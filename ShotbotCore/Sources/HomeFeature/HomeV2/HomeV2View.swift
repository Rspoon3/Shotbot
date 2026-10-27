//
//  HomeV2View.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import Models
import PhotosUI
import SwiftUI

/// A home screen built on cached layers: picking a background, color or padding only changes how the layers are put
/// together, so it responds immediately.
public struct HomeV2View: View {
    @State private var viewModel = HomeV2ViewModel()
    @State private var showPhotosPicker = false
    @State private var showFileImporter = false
    @State private var selection = [PhotosPickerItem]()

    // MARK: - Initializer

    public init() { }

    // MARK: - Body

    public var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            if viewModel.items.count > 1 {
                Picker("Image Type", selection: $viewModel.imageType) {
                    ForEach(ImageType.allCases) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            preview

            if viewModel.hasContent {
                controls
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .navigationTitle("Shotbot V2")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $showPhotosPicker, selection: $selection, matching: .any(of: [.images, .videos]))
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image, .movie], allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }

            Task { await viewModel.load(files: urls) }
        }
        .onChange(of: selection) { _, newValue in
            guard !newValue.isEmpty else { return }

            Task {
                await viewModel.load(newValue)
                selection = []
            }
        }
        .overlay(alignment: .top) {
            if let message = viewModel.statusMessage {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.default, value: viewModel.statusMessage)
        .overlay {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)

                    if !viewModel.loadingMessage.isEmpty {
                        Text(viewModel.loadingMessage)
                            .font(.subheadline)
                    }
                }
                .padding(20)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .onChange(of: viewModel.recipe) { _, _ in
            viewModel.rebuildVideo()
        }
        .alert(error: $viewModel.error)
        .toolbar { toolbar }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var preview: some View {
        if let video = viewModel.video {
            VideoPreview(video: video)
                .padding(.horizontal, 8)
                .draggable(ExportVideo(video: video))
        } else if viewModel.items.isEmpty {
            placeholder
        } else if viewModel.imageType == .combined, viewModel.items.count > 1 {
            image(viewModel.combinedImage)
        } else if viewModel.items.count == 1, let item = viewModel.items.first {
            image(viewModel.sceneImage(for: item.id))
        } else {
            @Bindable var viewModel = viewModel

            TabView(selection: $viewModel.selectedItemID) {
                ForEach(viewModel.items) { item in
                    image(viewModel.sceneImage(for: item.id))
                        .tag(Optional(item.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }

    @ViewBuilder
    private func image(_ image: CIImage?) -> some View {
        if let image {
            MetalImageView(image: image)
                .padding(.horizontal, 8)
                .draggable(ExportImage(image: image))
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var placeholder: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            Button {
                showPhotosPicker = true
            } label: {
                Text("Select Photos")
                    .font(.headline)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)

            Button("Select From Files") {
                showFileImporter = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var controls: some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BackgroundStyle.allCases) { style in
                        swatch(style)
                    }
                }
                .padding(.horizontal)
            }

            if viewModel.recipe.background == .photo {
                HStack(spacing: 8) {
                    Text("Blur")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(BackgroundBlur.allCases) { blur in
                        chip(blur.title, isSelected: viewModel.recipe.blur == blur) {
                            viewModel.recipe.blur = blur
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CanvasAspect.allCases) { aspect in
                        chip(aspect.title, isSelected: viewModel.recipe.aspect == aspect) {
                            viewModel.recipe.aspect = aspect
                        }
                    }

                    chip("Shadow", isSelected: viewModel.recipe.hasShadow) {
                        viewModel.recipe.hasShadow.toggle()
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .tint(isSelected ? .accentColor : .secondary)
            .fontWeight(isSelected ? .semibold : .regular)
    }

    private func swatch(_ style: BackgroundStyle) -> some View {
        Button {
            viewModel.recipe.background = style
        } label: {
            ZStack {
                if style == .transparent {
                    Color(.systemGray5)
                    Image(systemName: "nosign")
                        .foregroundStyle(.secondary)
                } else if let thumbnail = BackgroundRenderer.thumbnail(style) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, lineWidth: viewModel.recipe.background == style ? 3 : 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(style.title)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if viewModel.hasContent {
                Button("Clear", role: .destructive) {
                    viewModel.clear()
                }
                .foregroundStyle(.red)
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            if let video = viewModel.exportVideo {
                styleMenu

                ShareLink(item: video, preview: SharePreview("Framed Video"))

                Menu {
                    Button {
                        Task { await viewModel.saveVideoToPhotos() }
                    } label: {
                        Label("Save to Photos", systemImage: "photo.badge.arrow.down")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            } else if !viewModel.items.isEmpty {
                styleMenu

                if viewModel.items.count > 1 {
                    Button {
                        viewModel.reverse()
                    } label: {
                        Label("Reverse Images", systemImage: "arrow.left.arrow.right")
                    }
                }

                if let export = viewModel.exportImage {
                    ShareLink(item: export, preview: SharePreview("Framed Screenshot"))
                }

                Menu {
                    Button {
                        viewModel.copy()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    Button {
                        Task { await viewModel.saveToPhotos() }
                    } label: {
                        Label("Save to Photos", systemImage: "photo.badge.arrow.down")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
    }

    /// Colors and views for the devices in the screenshots, and the device itself when more than one fits.
    @ViewBuilder
    private var styleMenu: some View {
        let options = viewModel.styleOptions
        let devices = viewModel.deviceChoices

        if !options.isEmpty || !devices.isEmpty {
            Menu {
                ForEach(options) { option in
                    if option.colors.count > 1 {
                        Section(options.count > 1 ? "\(option.deviceName) Color" : "Color") {
                            Picker(option.deviceName, selection: colorSelection(for: option)) {
                                ForEach(option.colors, id: \.self) { color in
                                    Text(color)
                                        .tag(color)
                                }
                            }
                        }
                    }

                    ForEach(option.screens) { screen in
                        Section([option.deviceName, screen.screenName, "View"].compactMap { $0 }.joined(separator: " ")) {
                            Picker(option.deviceName, selection: viewSelection(for: screen)) {
                                ForEach(screen.views, id: \.self) { view in
                                    Text(view)
                                        .tag(view)
                                }
                            }
                        }
                    }
                }

                if !devices.isEmpty {
                    Section("Device") {
                        ForEach(devices, id: \.deviceFrame) { device in
                            Button(device.name) {
                                viewModel.setDevice(device)
                            }
                        }
                    }
                }
            } label: {
                Label("Frame Style", systemImage: "paintpalette")
            }
        }
    }

    // MARK: - Private Helpers

    private func colorSelection(for option: HomeV2ViewModel.StyleOption) -> Binding<String> {
        Binding {
            option.selectedColor ?? ""
        } set: { color in
            viewModel.setColor(color, forDeviceNamed: option.deviceName)
        }
    }

    private func viewSelection(for screen: HomeV2ViewModel.StyleOption.Screen) -> Binding<String> {
        Binding {
            screen.selectedView
        } set: { view in
            viewModel.setView(view, forViewKey: screen.viewKey)
        }
    }
}
