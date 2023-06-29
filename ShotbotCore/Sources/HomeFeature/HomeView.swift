//
//  HomeView.swift
//  Shot Bot
//
//  Created by Richard Witherspoon on 4/20/23.
//

import SwiftUI
import PhotosUI
import AlertToast
import Persistence
import Models
import Purchases
import MediaManager


public struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var persistenceManager: PersistenceManager
    @Environment(\.scenePhase) var scenePhase
    private let photoLibraryManager: PhotoLibraryManager

    
    // MARK: - Initializer
    
    public init(photoLibraryManager: PhotoLibraryManager) {
        self.photoLibraryManager = photoLibraryManager
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                picker
                mainContent
                photoButton
            }
            .navigationTitle("Shotbot")
            .photosPicker(
                isPresented: $viewModel.showPhotosPicker,
                selection: $viewModel.imageSelections,
                matching: persistenceManager.imageSelectionType.filter,
                photoLibrary: .shared()
            )
            .onChange(of: viewModel.imageSelections) { newValue in
                Task(priority: .userInitiated) {
                    await viewModel.imageSelectionsDidChange()
                }
            }
            .dropDestination(for: Data.self) { items, location in
                Task(priority: .userInitiated) {
                    await viewModel.didDropItem(items)
                }
                return true
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage)
                )
            }
            .toast(isPresenting: $viewModel.showQuickSaveToast, duration: 2) {
                AlertToast(
                    displayMode: .hud,
                    type: .regular,
                    title: "Image Saved",
                    style: .style(
                        backgroundColor: .blue,
                        titleColor: .white
                    )
                )
            }
            .toast(isPresenting: $viewModel.showCopyToast, duration: 2) {
                AlertToast(
                    displayMode: .hud,
                    type: .regular,
                    title: "Image Copied",
                    style: .style(
                        backgroundColor: .blue,
                        titleColor: .white
                    )
                )
            }
            .toast(isPresenting: $viewModel.showAutoSaveToast, duration: 3) {
                AlertToast(
                    displayMode: .hud,
                    type: .regular,
                    title: viewModel.toastText,
                    style: .style(
                        backgroundColor: .blue,
                        titleColor: .white
                    )
                )
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(.all, 20)
                        .background(
                            .thinMaterial,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
            }
            .task {
                await photoLibraryManager.requestPhotoLibraryAdditionAuthorization()
            }
            .onChange(of: scenePhase) { newValue in
                guard newValue == .background || newValue == .active else { return }
                viewModel.clearImagesOnAppBackground()
            }
            .onAppear {
                Task {
                    await viewModel.changeImageQualityIfNeeded()
                }
            }
            .sheet(isPresented: $viewModel.showPurchaseView) {
                NavigationView {
                    PurchaseView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Dismiss") {
                                    viewModel.showPurchaseView = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private var picker: some View {
        if viewModel.imageResults.hasMultipleImages {
            Picker("Image Type", selection: $viewModel.imageType) {
                ForEach(ImageType.allCases) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.viewState {
        case .combinedPlaceholder:
            ProgressView("Combining Images...")
                .frame(maxHeight: .infinity, alignment: .center)
        case .individualPlaceholder:
            placeholder
        case .individualImages(let shareableImages):
            tabView(shareableImages: shareableImages)
        case .combinedImages(let shareableImage):
            Image(uiImage: shareableImage.framedScreenshot)
                .resizable()
                .scaledToFit()
                .draggable(Image(uiImage: shareableImage.framedScreenshot))
                .contextMenu {
                    Button {
                        Task(priority: .userInitiated) {
                            await viewModel.save(shareableImage.framedScreenshot)
                        }
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    
                    Button {
                        viewModel.copy(shareableImage.framedScreenshot)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    
                    PurchaseShareLink(
                        items: [shareableImage.url],
                        showPurchaseView: $viewModel.showPurchaseView
                    )
                }
                .padding()
                .id(UUID())
                .frame(maxHeight: .infinity, alignment: .center)
                .onTapGesture(count: 2) {
                    viewModel.copy(shareableImage.framedScreenshot)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        PurchaseShareLink(
                            items: [shareableImage.url],
                            showPurchaseView: $viewModel.showPurchaseView
                        )
                    }
                }
        }
    }
    
    private var placeholder: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 200)
            .padding()
            .foregroundColor(.secondary)
            .frame(maxHeight: .infinity)
            .onTapGesture {
                viewModel.selectPhotos()
            }
    }
    
    private var photoButton: some View {
        Button {
            viewModel.selectPhotos()
        } label:{
            Text("Select Photos")
                .font(.headline)
                .frame(maxWidth: 300)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isLoading)
        .padding([.bottom, .horizontal])
    }
    
    private func tabView(shareableImages: [ShareableImage]) -> some View {
        TabView {
            ForEach(shareableImages) { shareableImage in
                Image(uiImage: shareableImage.framedScreenshot)
                    .resizable()
                    .scaledToFit()
                    .contextMenu {
                        Button {
                            Task(priority: .userInitiated) {
                                await viewModel.save(shareableImage.framedScreenshot)
                            }
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        
                        Button {
                            viewModel.copy(shareableImage.framedScreenshot)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        
                        PurchaseShareLink(
                            items: [shareableImage.url],
                            showPurchaseView: $viewModel.showPurchaseView
                        )
                    }
                    .padding([.horizontal, .top])
                    .padding(.bottom, 40)
                    .draggable(Image(uiImage: shareableImage.framedScreenshot))
                    .onTapGesture(count: 2) {
                        viewModel.copy(shareableImage.framedScreenshot)
                    }
            }
        }
        .tabViewStyle(.page)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                PurchaseShareLink(
                    items: shareableImages.map(\.url),
                    showPurchaseView: $viewModel.showPurchaseView
                )
            }
        }
        .onAppear {
            let appearance = UIPageControl.appearance()
            appearance.currentPageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.75)
            appearance.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.33)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView(photoLibraryManager: .live)
                .environmentObject(PersistenceManager.shared)
                .environmentObject(PurchaseManager.shared)
        }
    }
}
