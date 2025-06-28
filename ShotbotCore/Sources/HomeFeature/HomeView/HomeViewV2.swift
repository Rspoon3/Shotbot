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
    @State private var selectedImages: [UIImage] = []
    @State private var imageSelections: [PhotosPickerItem] = []
    @State private var showPhotosPicker = false
    @State private var showShareSheet = false
    @State private var exportedImage: UIImage?
    @State private var isExporting = false
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
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
        .sheet(isPresented: $showShareSheet) {
            if let exportedImage {
                ShareSheet(items: [exportedImage])
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
    
    private func framedImagesView(_ images: [UIImage]) -> some View {
        VStack(spacing: 16) {
            FramedScreenshotsComposition(
                screenshots: images,
                showBorder: true
            )
            .onDrag {
                if let exportedImage {
                    return NSItemProvider(object: exportedImage)
                } else {
                    let exportView = FramedScreenshotsComposition(
                        screenshots: images,
                        frameSize: CGSize(width: 400, height: 800)
                    )
                    let renderer = ImageRenderer(content: exportView)
                    renderer.scale = displayScale
                    
                    if let dragImage = renderer.uiImage {
                        return NSItemProvider(object: dragImage)
                    }
                }
                return NSItemProvider()
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
    
    private func handleDroppedItems(_ items: [Data]) async {
        var droppedImages: [UIImage] = []
        
        for data in items {
            if let image = UIImage(data: data) {
                droppedImages.append(image)
            }
        }
        
        await MainActor.run {
            selectedImages = droppedImages
        }
    }
    
    private func loadSelectedImages(from items: [PhotosPickerItem]) async {
        var loadedImages: [UIImage] = []
        
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append(image)
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
        
        let exportView: FramedScreenshotsComposition
        
        if selectedImages.count == 1 {
            // Single image export - use fixed size for high quality
            exportView = FramedScreenshotsComposition(
                screenshots: selectedImages,
                frameSize: CGSize(width: 400, height: 800)
            )
        } else {
            // Multiple images export - use fixed size for consistent output
            exportView = FramedScreenshotsComposition(
                screenshots: selectedImages,
                frameSize: CGSize(width: 400, height: 800)
            )
        }
        
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = displayScale
        
        if let image = renderer.uiImage {
            exportedImage = image
            showShareSheet = true
        }
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
