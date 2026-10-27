//
//  HomeV2ViewModel.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage
import MediaManager
import Models
import Observation
import Persistence
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Runs the layered home screen.
///
/// Each screenshot is drawn once into cached layers by `LayerStore`. Everything the user can change afterward, such as the
/// background, padding and shadow, only changes how the layers are put together, which is cheap. A device color or view
/// redraws just the one layer that depends on it, in the background, while the old picture stays up.
@MainActor
@Observable
public final class HomeV2ViewModel {
    /// One screenshot and the device it is framed in.
    struct Item: Identifiable, Sendable {
        let id = UUID()
        let screenshot: UIImage
        var device: DeviceInfo
        /// Every device that fits the screenshot's size, for choosing between them.
        let candidates: [DeviceInfo]
    }

    /// The color and view choices of one device in the current screenshots.
    struct StyleOption: Identifiable {
        struct Screen: Identifiable {
            let viewKey: String
            let screenName: String?
            let views: [String]
            let selectedView: String

            var id: String { viewKey }
        }

        let deviceName: String
        let colors: [String]
        let selectedColor: String?
        let screens: [Screen]

        var id: String { deviceName }
    }

    private(set) var items = [Item]()
    private(set) var renders = [UUID: DeviceRender]()
    /// Backgrounds that are slow to draw, drawn ahead of time for the sizes the scenes need.
    private(set) var backgrounds = [String: CIImage]()
    private(set) var isLoading = false
    private(set) var loadingMessage = ""
    /// A screen recording framed in the current scene, playing live instead of screenshots.
    private(set) var video: PreparedVideo?
    private(set) var videoDevice: DeviceInfo?
    @ObservationIgnored private var videoSourceURL: URL?
    @ObservationIgnored private var videoTask: Task<Void, Never>?
    private(set) var statusMessage: String?
    var imageType = ImageType.individual
    var recipe = SceneRecipe()
    var selectedItemID: UUID?
    var error: Error?

    @ObservationIgnored private let persistence: any PersistenceManaging
    @ObservationIgnored private let store = LayerStore.shared
    @ObservationIgnored private var renderTasks = [UUID: Task<Void, Never>]()
    @ObservationIgnored private var backgroundTasks = [String: Task<Void, Never>]()
    @ObservationIgnored private var prewarmTask: Task<Void, Never>?
    /// The PNG files for the pictures on screen, made once and shared by sharing, dragging, copying and saving.
    @ObservationIgnored private var exports = [ExportKey: PNGExport]()
    /// Changes whenever a layer or a background is replaced, so a picture made from older ones is never reused.
    @ObservationIgnored private var revision = 0

    /// What identifies one picture: which screenshots, how they are put together, and which layers it was made from.
    private struct ExportKey: Hashable {
        let ids: [UUID]
        let recipe: SceneRecipe
        let revision: Int
    }

    // MARK: - Initializer

    public init() {
        persistence = PersistenceManager.shared
    }

    /// Whether there is anything to show, screenshots or a video.
    var hasContent: Bool {
        !items.isEmpty || videoSourceURL != nil
    }

    // MARK: - Scene

    /// The picture of one screenshot, once its layers are drawn.
    func sceneImage(for id: UUID) -> CIImage? {
        scene(of: [id])
    }

    /// The picture of every screenshot side by side, once all their layers are drawn.
    var combinedImage: CIImage? {
        scene(of: items.map(\.id))
    }

    /// The screenshots that sharing, copying and saving use.
    private var currentIDs: [UUID] {
        if imageType == .combined, items.count > 1 {
            return items.map(\.id)
        }

        return (selectedItem?.id).map { [$0] } ?? []
    }

    /// The file for the picture that sharing, copying and saving use.
    var exportImage: ExportImage? {
        exportImage(of: currentIDs)
    }

    /// The file for the picture of some screenshots, such as the page being dragged.
    func exportImage(of ids: [UUID]) -> ExportImage? {
        exportJob(of: ids).map(ExportImage.init)
    }

    // MARK: - Style

    /// The devices in the current screenshots that have colors or views to choose from.
    var styleOptions: [StyleOption] {
        var seen = Set<String>()
        var options = [StyleOption]()

        let devices = items.map(\.device) + (videoDevice.map { [$0] } ?? [])

        for device in devices where device.hasColorOptions || device.hasViewOptions {
            guard seen.insert(device.name).inserted else { continue }

            let group = devices.filter { $0.name == device.name }
            var screenKeys = Set<String>()

            let screens = group.compactMap { member -> StyleOption.Screen? in
                guard member.hasViewOptions, screenKeys.insert(member.viewPreferenceKey).inserted else { return nil }

                return StyleOption.Screen(
                    viewKey: member.viewPreferenceKey,
                    screenName: member.screenName,
                    views: member.views,
                    selectedView: member.viewName ?? ""
                )
            }

            options.append(StyleOption(
                deviceName: device.name,
                colors: device.colors,
                selectedColor: device.colorName,
                screens: screens
            ))
        }

        return options
    }

    /// The devices that fit the selected screenshot, when more than one does.
    var deviceChoices: [DeviceInfo] {
        guard let item = selectedItem, item.candidates.count > 1 else { return [] }
        return item.candidates
    }

    var selectedItem: Item? {
        items.first { $0.id == selectedItemID } ?? items.first
    }

    /// Saves a color as the default for a device and draws it on every screenshot in that device.
    func setColor(_ color: String, forDeviceNamed name: String) {
        persistence.setPreferredColor(color, for: name)

        if let device = videoDevice {
            videoDevice = device.withColor(color)
            rebuildVideo()
            return
        }

        restyle(where: { $0.device.name == name }) { $0.withColor(color) }
    }

    /// Saves a view as the default for a screen and draws it on every screenshot of that screen.
    func setView(_ view: String, forViewKey key: String) {
        persistence.setPreferredView(view, forKey: key)

        if let device = videoDevice {
            videoDevice = device.withView(view)
            rebuildVideo()
            return
        }

        restyle(where: { $0.device.viewPreferenceKey == key }) { $0.withView(view) }
    }

    /// Uses another device that fits the selected screenshot.
    func setDevice(_ device: DeviceInfo) {
        guard let index = items.firstIndex(where: { $0.id == selectedItem?.id }) else { return }

        persistence.setPreferredDeviceFrame(device.deviceFrame, for: items[index].screenshot.size)
        items[index].device = persistence.applyingPreferredStyle(to: device)
        render(items[index])
    }

    // MARK: - Actions

    /// Loads the picked photos and starts drawing their layers.
    func load(_ pickerItems: [PhotosPickerItem]) async {
        guard !pickerItems.isEmpty else { return }

        if let video = pickerItems.first(where: \.isVideo) {
            do {
                guard let url = try await video.loadVideoURL() else { throw HomeV2Error.noSupportedScreenshots }
                await loadVideo(at: url)
            } catch {
                self.error = error
            }

            return
        }

        isLoading = true
        loadingMessage = ""
        defer { isLoading = false }

        // Every photo is fetched and decoded at the same time, off the main thread.
        let screenshots = await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (index, pickerItem) in pickerItems.enumerated() {
                group.addTask {
                    guard let data = try? await pickerItem.loadTransferable(type: Data.self) else { return (index, nil) }

                    return (index, await UIImage(data: data)?.byPreparingForDisplay())
                }
            }

            var results = [(Int, UIImage?)]()

            for await result in group {
                results.append(result)
            }

            return results.sorted { $0.0 < $1.0 }.compactMap(\.1)
        }

        show(screenshots.compactMap(makeItem))
    }

    /// Loads files from the Files app: screenshots, or a screen recording.
    func load(files urls: [URL]) async {
        guard !urls.isEmpty else { return }

        let isMovie = { (url: URL) in
            UTType(filenameExtension: url.pathExtension)?.conforms(to: .movie) == true
        }

        do {
            if let movie = urls.first(where: isMovie) {
                await loadVideo(at: try Self.copyToTemporaryDirectory(movie))
                return
            }

            isLoading = true
            loadingMessage = ""
            defer { isLoading = false }

            let screenshots = try await withThrowingTaskGroup(of: (Int, UIImage?).self) { group in
                for (index, url) in urls.enumerated() {
                    group.addTask {
                        let copy = try Self.copyToTemporaryDirectory(url)
                        defer { try? FileManager.default.removeItem(at: copy) }

                        return (index, await UIImage(data: try Data(contentsOf: copy))?.byPreparingForDisplay())
                    }
                }

                var results = [(Int, UIImage?)]()

                for try await result in group {
                    results.append(result)
                }

                return results.sorted { $0.0 < $1.0 }.compactMap(\.1)
            }

            show(screenshots.compactMap(makeItem))
        } catch {
            self.error = error
        }
    }

    /// Sets up a screen recording in the scene, matching its size to a device. The recording is kept, so the
    /// background, shape or device color can change while it plays.
    func loadVideo(at sourceURL: URL) async {
        isLoading = true
        loadingMessage = "Preparing video…"
        defer { isLoading = false }

        do {
            let size = try await VideoFramer.size(ofVideoAt: sourceURL)
            let device: DeviceInfo

            switch DeviceInfo.match(for: size) {
            case .none:
                throw HomeV2Error.noSupportedScreenshots
            case .exact(let match):
                device = match
            case .ambiguous(let candidates):
                let cached = persistence.preferredDeviceFrame(for: size)
                device = candidates.first { $0.deviceFrame == cached } ?? candidates[0]
            }

            let styled = persistence.applyingPreferredStyle(to: device)
            let prepared = try await VideoScene.prepare(sourceURL: sourceURL, device: styled, recipe: recipe)

            clear()
            videoSourceURL = sourceURL
            videoDevice = styled
            video = prepared
        } catch {
            self.error = error
        }
    }

    /// Prepares the current recording again after the recipe or the device changed. The old picture keeps playing
    /// until the new one is ready.
    func rebuildVideo() {
        guard let sourceURL = videoSourceURL, let device = videoDevice else { return }

        videoTask?.cancel()

        let recipe = recipe

        videoTask = Task { [weak self] in
            do {
                let prepared = try await VideoScene.prepare(sourceURL: sourceURL, device: device, recipe: recipe)

                guard let self, !Task.isCancelled else { return }

                video = prepared
            } catch {
                self?.error = error
            }
        }
    }

    /// The video as something to share or drag out, rendered only when it is asked for.
    var exportVideo: ExportVideo? {
        video.map(ExportVideo.init)
    }

    func saveVideoToPhotos() async {
        guard let exportVideo else { return }

        isLoading = true
        loadingMessage = "Exporting video…"
        defer { isLoading = false }

        do {
            let url = try await exportVideo.writeFile()
            try await PhotoLibraryManager.live.saveVideo(url)
            try? FileManager.default.removeItem(at: url)
            show("Saved to Photos")
        } catch {
            self.error = error
        }
    }

    /// Brings everything that depends on the recipe up to date: the video, the slow backgrounds and the files.
    func recipeDidChange() {
        rebuildVideo()
        refreshBackgrounds()
        scheduleExport()
    }

    func reverse() {
        items.reverse()
        refreshBackgrounds()
        scheduleExport()
    }

    func clear() {
        cancelRenders()
        videoTask?.cancel()
        video = nil
        videoDevice = nil
        videoSourceURL = nil
        items = []
        renders = [:]
        resetBackgrounds()
        selectedItemID = nil
        imageType = .individual
    }

    func copy() async {
        guard let export = exportJob(of: currentIDs) else { return }

        do {
            let url = try await export.file()
            let data = try await Task.detached { try Data(contentsOf: url) }.value

            UIPasteboard.general.setData(data, forPasteboardType: UTType.png.identifier)
            show("Copied")
        } catch {
            self.error = error
        }
    }

    func saveToPhotos() async {
        guard let export = exportJob(of: currentIDs) else { return }

        do {
            try await PhotoLibraryManager.live.savePhoto(try await export.file())
            show("Saved to Photos")
        } catch {
            self.error = error
        }
    }

    /// Starts making the file for the picture on screen once the edits have settled, so sharing it finds it ready.
    func scheduleExport() {
        prewarmTask?.cancel()

        prewarmTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))

            guard !Task.isCancelled, let self else { return }

            exportJob(of: currentIDs)?.start()
        }
    }

    // MARK: - Private Helpers

    /// The picture of some screenshots, using a background drawn ahead of time when the style needs one.
    private func scene(of ids: [UUID]) -> CIImage? {
        let drawn = ids.compactMap { renders[$0] }

        guard !drawn.isEmpty, drawn.count == ids.count else { return nil }

        let background = backgroundKey(of: ids, renders: drawn).flatMap { backgrounds[$0] }

        return SceneComposer.compose(drawn, recipe: recipe, background: background)
    }

    /// The file for one picture, made the first time the picture is asked for.
    private func exportJob(of ids: [UUID]) -> PNGExport? {
        let key = ExportKey(ids: ids, recipe: recipe, revision: revision)

        if let export = exports[key] { return export }

        guard let image = scene(of: ids) else { return nil }

        // Files for older pictures are no use any more.
        exports = exports.filter { $0.key.revision == revision }

        let export = PNGExport(image: image)
        exports[key] = export
        return export
    }

    /// What identifies the drawn background of a picture, or `nil` when its style is quick enough to draw every time.
    private func backgroundKey(of ids: [UUID], renders drawn: [DeviceRender]) -> String? {
        guard let size = SceneComposer.canvasSize(for: drawn, recipe: recipe) else { return nil }

        // The blurred style is made from the first device, so it changes with that device's screenshot and color.
        let first = items.first { $0.id == ids.first }
        let source = "\(ids.first?.uuidString ?? "")|\(first?.device.deviceFrame ?? "")"

        return LayerStore.backgroundKey(recipe.background, size: size, blur: recipe.blur, sourceKey: source)
    }

    /// Draws the slow backgrounds the pictures need, in the background, and forgets the ones they no longer use. A picture
    /// shows a quickly drawn version until its background is ready.
    private func refreshBackgrounds() {
        var wanted = [String: (size: CGSize, source: CIImage, sourceKey: String)]()

        var groups = items.map { [$0.id] }

        if items.count > 1 {
            groups.append(items.map(\.id))
        }

        for ids in groups {
            let drawn = ids.compactMap { renders[$0] }

            guard
                drawn.count == ids.count,
                let size = SceneComposer.canvasSize(for: drawn, recipe: recipe),
                let key = backgroundKey(of: ids, renders: drawn)
            else {
                continue
            }

            let first = items.first { $0.id == ids.first }
            wanted[key] = (size, drawn[0].device, "\(ids[0].uuidString)|\(first?.device.deviceFrame ?? "")")
        }

        let before = backgrounds.count
        backgrounds = backgrounds.filter { wanted[$0.key] != nil }

        if backgrounds.count != before {
            revision += 1
        }

        for (key, task) in backgroundTasks where wanted[key] == nil {
            task.cancel()
            backgroundTasks[key] = nil
        }

        let store = store
        let style = recipe.background
        let blur = recipe.blur

        for (key, request) in wanted where backgrounds[key] == nil && backgroundTasks[key] == nil {
            backgroundTasks[key] = Task { [weak self] in
                let image = try? await store.background(
                    style,
                    size: request.size,
                    blur: blur,
                    source: request.source,
                    sourceKey: request.sourceKey
                )

                guard let self else { return }

                backgroundTasks[key] = nil

                guard let image, !Task.isCancelled else { return }

                backgrounds[key] = image
                revision += 1
                scheduleExport()
            }
        }
    }

    private func resetBackgrounds() {
        backgroundTasks.values.forEach { $0.cancel() }
        backgroundTasks = [:]
        backgrounds = [:]
        exports = [:]
        revision += 1
    }

    /// Replaces the current content with newly loaded screenshots and starts drawing their layers.
    private func show(_ loaded: [Item]) {
        guard !loaded.isEmpty else {
            error = HomeV2Error.noSupportedScreenshots
            return
        }

        cancelRenders()
        videoTask?.cancel()
        video = nil
        videoDevice = nil
        videoSourceURL = nil
        items = loaded
        renders = [:]
        resetBackgrounds()
        selectedItemID = loaded.first?.id

        if loaded.count == 1 {
            imageType = .individual
        }

        loaded.forEach(render)
    }

    /// Copies a file picked in the Files app into the temporary directory, where the app is allowed to read it.
    private nonisolated static func copyToTemporaryDirectory(_ url: URL) throws -> URL {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let copy = URL.temporaryDirectory.appending(path: "Source \(UUID()).\(url.pathExtension)")
        try FileManager.default.copyItem(at: url, to: copy)
        return copy
    }

    private func makeItem(_ screenshot: UIImage) -> Item? {
        let size = screenshot.size

        switch DeviceInfo.match(for: size) {
        case .none:
            return nil
        case .exact(let device):
            return Item(screenshot: screenshot, device: persistence.applyingPreferredStyle(to: device), candidates: [device])
        case .ambiguous(let candidates):
            let cached = persistence.preferredDeviceFrame(for: size)
            let device = candidates.first { $0.deviceFrame == cached } ?? candidates[0]
            return Item(screenshot: screenshot, device: persistence.applyingPreferredStyle(to: device), candidates: candidates)
        }
    }

    private func restyle(where matches: (Item) -> Bool, apply: (DeviceInfo) -> DeviceInfo) {
        for index in items.indices where matches(items[index]) {
            items[index].device = apply(items[index].device)
            render(items[index])
        }
    }

    /// Draws a screenshot's layers in the background. The previous picture stays until the new one is ready.
    private func render(_ item: Item) {
        renderTasks[item.id]?.cancel()

        let store = store

        renderTasks[item.id] = Task { [weak self] in
            do {
                let render = try await store.deviceRender(id: item.id, screenshot: item.screenshot, device: item.device)

                guard let self, !Task.isCancelled, items.contains(where: { $0.id == item.id }) else { return }

                renders[item.id] = render
                revision += 1
                refreshBackgrounds()
                scheduleExport()
            } catch {
                self?.error = error
            }
        }
    }

    private func cancelRenders() {
        renderTasks.values.forEach { $0.cancel() }
        renderTasks = [:]
    }

    private func show(_ message: String) {
        statusMessage = message

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            statusMessage = nil
        }
    }
}

/// Why the layered home screen couldn't use the photos.
enum HomeV2Error: LocalizedError {
    case noSupportedScreenshots

    var errorDescription: String? {
        "None of the photos match a device Shotbot can frame."
    }
}
