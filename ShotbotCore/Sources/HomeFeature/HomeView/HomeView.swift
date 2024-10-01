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
    @StateObject var manager = AppIntentManager.shared
    @StateObject var viewModel = HomeViewModel()
    @EnvironmentObject var tabManager: TabManager
    @Environment(\.scenePhase) var scenePhase

    // MARK: - Initializer
    
    public init(viewModel: HomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("\(manager.selectDurationIntentID ?? -1)")
                picker
                mainContent
                pickerMenu
            }
            #if os(iOS)
            .navigationTitle("Shotbot")
            #endif
            .photosPicker(
                isPresented: $viewModel.showPhotosPicker,
                selection: $viewModel.imageSelections,
                matching: viewModel.photoFilter,
                photoLibrary: .shared()
            )
            .onChange(of: viewModel.imageSelections) { newValue in
                Task(priority: .userInitiated) {
                    await viewModel.imageSelectionsDidChange()
                }
            }
            .contentShape(Rectangle())
            .dropDestination(for: Data.self) { items, location in
                Task(priority: .userInitiated) {
                    await viewModel.didDropItem(items)
                }
                return true
            }
            .alert(error: $viewModel.error) {
                viewModel.clearContent()
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
                if viewModel.showLoadingSpinner {
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
                await viewModel.requestPhotoLibraryAdditionAuthorization()
                await viewModel.changeImageQualityIfNeeded()
            }
            .onChange(of: scenePhase) { newValue in
                guard newValue == .background || newValue == .active else { return }
                viewModel.clearImagesOnAppBackground()
            }
            .onOpenURL { url in
                tabManager.selectedTab = .home
                Task {
                    await viewModel.didOpenViaDeepLink(url)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.canShowClearButton {
                        Button("Clear", role: .destructive) {
                            viewModel.clearContent()
                        }.foregroundColor(.red)
                    }
                }
            }
            .fileImporter(
                isPresented: $viewModel.isImportingFile,
                allowedContentTypes: [.image, .png, .jpeg],
                allowsMultipleSelection: true
            ) { viewModel.fileImportCompletion(result: $0) }
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
            individualImagesView(shareableImages)
        case .combinedImages(let shareableImage):
            Image(uiImage: shareableImage.framedScreenshot)
                .resizable()
                .scaledToFit()
                .draggable(Image(uiImage: shareableImage.framedScreenshot))
                .contextMenu {
                    contextMenu(shareableImage: shareableImage)
                }
                .padding()
                .frame(maxHeight: .infinity, alignment: .center)
                .onTapGesture(count: 2) {
                    viewModel.copy(shareableImage.framedScreenshot)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            Task {
                                await viewModel.reverseImages()
                            }
                        } label: {
                            Label("Reverse Images", systemImage: "arrow.left.arrow.right")
                        }
                        .disabled(viewModel.isLoading)

                        PurchaseShareLink(
                            items: [shareableImage.url],
                            showPurchaseView: $viewModel.showPurchaseView
                        )
                    }
                }
        }
    }
    
    private var importFileButton: some View {
        Button {
            viewModel.isImportingFile = true
        } label: {
            Label("Select From Files", systemImage: "doc")
        }
    }
    
    private var placeholder: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .contextMenu { importFileButton }
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
            .onTapGesture { viewModel.selectPhotos() }
    }
    
    private var pickerMenu: some View {
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
        .contextMenu { importFileButton }
        .padding([.bottom, .horizontal])
    }
    
    private func tabView(shareableImages: [ShareableImage]) -> some View {
        TabView {
            ForEach(shareableImages) { shareableImage in
                Image(uiImage: shareableImage.framedScreenshot)
                    .resizable()
                    .scaledToFit()
                    .contextMenu {
                        contextMenu(shareableImage: shareableImage)
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
        .onAppear {
            let appearance = UIPageControl.appearance()
            appearance.currentPageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.75)
            appearance.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.33)
        }
    }
    
    private func gridView(shareableImages: [ShareableImage]) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 400))],
                spacing: 20
            ) {
                ForEach(shareableImages) { shareableImage in
                    Image(uiImage: shareableImage.framedScreenshot)
                        .resizable()
                        .scaledToFit()
                        .contextMenu {
                            contextMenu(shareableImage: shareableImage)
                        }
                        .draggable(Image(uiImage: shareableImage.framedScreenshot))
                        .onTapGesture(count: 2) {
                            viewModel.copy(shareableImage.framedScreenshot)
                        }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    private func contextMenu(shareableImage: ShareableImage) -> some View {
        Button {
            Task(priority: .userInitiated) {
                await viewModel.saveToPhotos(shareableImage.framedScreenshot)
            }
        } label: {
            Label("Save To Photos", systemImage: "photo")
        }
        
        Button {
            viewModel.saveToiCloud(shareableImage.url)
        } label: {
            Label("Save To Files", systemImage: "icloud")
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
    
    private func individualImagesView(_ shareableImages: [ShareableImage]) -> some View {
        Group {
            if viewModel.showGridView {
                gridView(shareableImages: shareableImages)
            } else {
                tabView(shareableImages: shareableImages)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let name = viewModel.viewTypeImageName {
                    Button {
                        viewModel.toggleIndividualViewType()
                    } label: {
                        Label("Individual View Type", systemImage: name)
                    }
                }

                PurchaseShareLink(
                    items: shareableImages.map(\.url),
                    showPurchaseView: $viewModel.showPurchaseView
                )
            }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView(
                viewModel: HomeViewModel(
                    photoLibraryManager: .empty(status: .authorized),
                    purchaseManager: MockPurchaseManager()
                )
            )
        }
    }
}
#endif
