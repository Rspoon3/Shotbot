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

        for item in items where item.device.hasColorOptions || item.device.hasViewOptions {
            guard seen.insert(item.device.name).inserted else { continue }

            let group = items.filter { $0.device.name == item.device.name }
            var screenKeys = Set<String>()

            let screens = group.compactMap { member -> StyleOption.Screen? in
                guard member.device.hasViewOptions, screenKeys.insert(member.device.viewPreferenceKey).inserted else { return nil }

                return StyleOption.Screen(
                    viewKey: member.device.viewPreferenceKey,
                    screenName: member.device.screenName,
                    views: member.device.views,
                    selectedView: member.device.viewName ?? ""
                )
            }

            options.append(StyleOption(
                deviceName: item.device.name,
                colors: item.device.colors,
                selectedColor: item.device.colorName,
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
        restyle(where: { $0.device.name == name }) { $0.withColor(color) }
    }

    /// Saves a view as the default for a screen and draws it on every screenshot of that screen.
    func setView(_ view: String, forViewKey key: String) {
        persistence.setPreferredView(view, forKey: key)
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

        isLoading = true
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

        guard !loaded.isEmpty else {
            error = HomeV2Error.noSupportedScreenshots
            return
        }

        cancelRenders()
        items = loaded
        renders = [:]
        selectedItemID = loaded.first?.id

        if loaded.count == 1 {
            imageType = .individual
        }

        loaded.forEach(render)
    }

    func reverse() {
        items.reverse()
    }

    func clear() {
        cancelRenders()
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
