//
//  HomeViewV2.swift
//  ShotbotCore
//
//  Created by Claude on 6/28/25.
//

import SwiftUI
import PhotosUI
import Models
import MediaManager

public struct HomeViewV2: View {
    @Environment(\.displayScale) private var displayScale
    @State private var selectedImages: [ProcessedScreenshot] = []
    @State private var imageSelections: [PhotosPickerItem] = []
    @State private var showPhotosPicker = false
    @State private var showShareSheet = false
    @State private var exportedImageURL: URL?
    @State private var isExporting = false
    @State private var spacing: CGFloat = 0
    @State private var padding: CGFloat = 0
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            Slider(value: $padding, in: 0...1000, step: 1)
            Slider(value: $spacing, in: 0...1000, step: 1)
            Button("Padding \(padding.formatted())") {
                padding = padding > 0 ? 0 : 1000
            }
            mainContent
            selectionButtons
        }
        .navigationTitle("Shotbot V2")
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $imageSelections,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: imageSelections) { _, newValues in
            Task {
                await loadSelectedImages(from: newValues)
            }
        }
        .overlay {
            if isExporting {
                ProgressView("Exporting...")
                    .scaleEffect(1.5)
                    .padding(.all, 20)
                    .background(
                        .thinMaterial,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }
        }
        .contentShape(Rectangle())
        .dropDestination(for: Data.self) { items, location in
            Task(priority: .userInitiated) {
                await handleDroppedItems(items)
            }
            return true
        }
        .sheet(isPresented: $showShareSheet, onDismiss: cleanupExportedImage) {
            if let exportedImageURL {
                ShareSheet(items: [exportedImageURL])
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if !selectedImages.isEmpty {
            framedImagesView(selectedImages)
        } else {
            placeholder
        }
    }
    
    private func framedImagesView(_ images: [ProcessedScreenshot]) -> some View {
        VStack(spacing: 16) {
            GeometryReader { geometry in
                FramedScreenshotsComposition(
                    screenshots: images,
                    spacing: scaledSpacing(for: geometry.size, images: images),
                    padding: scaledPadding(for: geometry.size, images: images)
                )
                .onDrag {
                    if let exportedImageURL {
                        return NSItemProvider(object: exportedImageURL as NSURL)
                    } else {
                        let exportView = FramedScreenshotsComposition(
                            screenshots: images,
                            spacing: spacing,
                            padding: padding
                        )
                        let renderer = ImageRenderer(content: exportView)
                        renderer.scale = displayScale
                        
                        if let dragImage = renderer.uiImage {
                            return NSItemProvider(object: dragImage)
                        }
                    }
                    return NSItemProvider()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(maxHeight: .infinity)
            
            PrimaryButton(title: "Export All") {
                Task {
                    await exportImages()
                }
            }
            .disabled(isExporting)
        }
    }
    
    private var placeholder: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 200)
            .padding()
            .contentShape(
                .hoverEffect,
                .rect(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
            .hoverEffect()
            .foregroundColor(.secondary)
            .frame(maxHeight: .infinity)
            .onTapGesture {
                showPhotosPicker = true
            }
    }
    
    private var selectionButtons: some View {
        VStack(spacing: 16) {
            PrimaryButton(title: "Select Photos") {
                showPhotosPicker = true
            }
        }
        .padding([.bottom, .horizontal])
    }
    
    // MARK: - Private Methods
    
    private func cleanupExportedImage() {
        if let exportedImageURL {
            try? FileManager.default.removeItem(at: exportedImageURL)
        }
        exportedImageURL = nil
    }
    
    private func scaledPadding(for availableSize: CGSize, images: [ProcessedScreenshot]) -> CGFloat {
        let baseWidth = calculateFrameWidth(for: images)
        let exportWidth = baseWidth + (2 * padding)
        let scale = availableSize.width / exportWidth
        
        return padding * scale
    }
    
    private func scaledSpacing(for availableSize: CGSize, images: [ProcessedScreenshot]) -> CGFloat {
        let baseWidth = calculateFrameWidth(for: images)
        let exportWidth = baseWidth + (2 * padding)
        let scale = availableSize.width / exportWidth
        
        return spacing * scale
    }
    
    private func calculateFrameWidth(for images: [ProcessedScreenshot]) -> CGFloat {
        var totalWidth: CGFloat = 0
        
        for processedScreenshot in images {
            if let frameImage = processedScreenshot.deviceInfo.frameImage() {
                totalWidth += frameImage.size.width
            }
        }
        
        // Add spacing between frames
        if images.count > 1 {
            totalWidth += spacing * CGFloat(images.count - 1)
        }
        
        return totalWidth
    }
    
    private func handleDroppedItems(_ items: [Data]) async {
        var droppedImages: [ProcessedScreenshot] = []
        
        for data in items {
            if let image = UIImage(data: data),
               let deviceInfo = DeviceInfo.all().first(where: { $0.inputSize == image.size }) {
                
                // Apply device-specific processing
                var processedImage = image
                if let cornerRadius = deviceInfo.cornerRadius {
                    processedImage = image.withRoundedCorners(radius: cornerRadius)
                }
                
                let processedScreenshot = ProcessedScreenshot(image: processedImage, deviceInfo: deviceInfo)
                droppedImages.append(processedScreenshot)
            }
        }
        
        await MainActor.run {
            selectedImages = droppedImages
        }
    }
    
    private func loadSelectedImages(from items: [PhotosPickerItem]) async {
        var loadedImages: [ProcessedScreenshot] = []
        
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let deviceInfo = DeviceInfo.all().first(where: { $0.inputSize == image.size }) {
                    
                    // Apply device-specific processing
                    var processedImage = image
                    if let cornerRadius = deviceInfo.cornerRadius {
                        processedImage = image.withRoundedCorners(radius: cornerRadius)
                    }
                    
                    let processedScreenshot = ProcessedScreenshot(
                        image: processedImage,
                        deviceInfo: deviceInfo
                    )
                    loadedImages.append(processedScreenshot)
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
        
        await MainActor.run {
            selectedImages = loadedImages
        }
    }
    
    @MainActor
    private func exportImages() async {
        guard !selectedImages.isEmpty else { return }
        
        isExporting = true
        defer { isExporting = false }
        
        let exportView = FramedScreenshotsComposition(
            screenshots: selectedImages,
            spacing: spacing,
            padding: padding
        )
        let renderer = ImageRenderer(content: exportView)
//        renderer.scale = displayScale
        
        if let image = renderer.uiImage,
           let imageData = image.pngData() {
            
            // Save to temporary file
            let temporaryURL = URL.temporaryDirectory.appending(path: "FramedScreenshot_\(UUID().uuidString).png")
            
            do {
                try imageData.write(to: temporaryURL)
                exportedImageURL = temporaryURL
                showShareSheet = true
            } catch {
                print("Failed to save image: \(error)")
            }
        }
        
//        1902 × 2620 frame and export too
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#if DEBUG
struct HomeViewV2_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeViewV2()
        }
    }
}
#endif
