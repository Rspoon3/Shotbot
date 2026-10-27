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
        renders[id].flatMap { SceneComposer.compose([$0], recipe: recipe) }
    }

    /// The picture of every screenshot side by side, once all their layers are drawn.
    var combinedImage: CIImage? {
        let drawn = items.compactMap { renders[$0.id] }
        guard drawn.count == items.count else { return nil }

        return SceneComposer.compose(drawn, recipe: recipe)
    }

    /// The picture that sharing, copying and saving use.
    var currentImage: CIImage? {
        if imageType == .combined, items.count > 1 {
            return combinedImage
        }

        return selectedItemID.flatMap(sceneImage(for:)) ?? items.first.flatMap { sceneImage(for: $0.id) }
    }

    var exportImage: ExportImage? {
        currentImage.map(ExportImage.init)
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

        var loaded = [Item]()

        for pickerItem in pickerItems {
            guard
                let data = try? await pickerItem.loadTransferable(type: Data.self),
                let screenshot = UIImage(data: data),
                let item = makeItem(screenshot)
            else {
                continue
            }

            loaded.append(item)
        }

        show(loaded)
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

            let loaded = try urls.compactMap { url -> Item? in
                let copy = try Self.copyToTemporaryDirectory(url)
                defer { try? FileManager.default.removeItem(at: copy) }

                return UIImage(data: try Data(contentsOf: copy)).flatMap(makeItem)
            }

            show(loaded)
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

    func reverse() {
        items.reverse()
    }

    func clear() {
        cancelRenders()
        videoTask?.cancel()
        video = nil
        videoDevice = nil
        videoSourceURL = nil
        items = []
        renders = [:]
        selectedItemID = nil
        imageType = .individual
    }

    func copy() {
        guard let image = currentImage, let data = try? store.pngData(of: image) else { return }

        UIPasteboard.general.setData(data, forPasteboardType: UTType.png.identifier)
        show("Copied")
    }

    func saveToPhotos() async {
        guard let export = exportImage else { return }

        do {
            let url = try export.writeFile()
            try await PhotoLibraryManager.live.savePhoto(url)
            try? FileManager.default.removeItem(at: url)
            show("Saved to Photos")
        } catch {
            self.error = error
        }
    }

    // MARK: - Private Helpers

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
        selectedItemID = loaded.first?.id

        if loaded.count == 1 {
            imageType = .individual
        }

        loaded.forEach(render)
    }

    /// Copies a file picked in the Files app into the temporary directory, where the app is allowed to read it.
    private static func copyToTemporaryDirectory(_ url: URL) throws -> URL {
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
                let render = try await Task.detached(priority: .userInitiated) {
                    try store.deviceRender(id: item.id, screenshot: item.screenshot, device: item.device)
                }.value

                guard let self, !Task.isCancelled, items.contains(where: { $0.id == item.id }) else { return }

                renders[item.id] = render
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
