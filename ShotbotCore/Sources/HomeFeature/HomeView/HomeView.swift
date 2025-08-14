//
//  HomeView.swift
//  Shotbot
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
import ReferralFeature
import ReferralService

public struct HomeView: View {
    @StateObject var manager = AppIntentManager.shared
    @StateObject var viewModel = HomeViewModel()
    @EnvironmentObject private var persistenceManager: PersistenceManager
    @EnvironmentObject var tabManager: TabManager
    @Environment(\.scenePhase) var scenePhase
    @State private var showReferrals = false
    @StateObject private var referralViewModel = ReferralViewModel()

    // MARK: - Initializer
    
    public init(viewModel: HomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            picker
            mainContent
            selectionButtons
        }
        .background {
            Color(.secondarySystemBackground).ignoresSafeArea(.all)
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
        .onChange(of: viewModel.imageSelections) { _, _ in
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
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .background || newValue == .active else { return }
            viewModel.clearImagesOnAppBackground()
        }
        .onReceive(manager.$selectTimeIntervalIntentID) { value in
            guard let value else { return }
            manager.selectTimeIntervalIntentID = nil
            tabManager.selectedTab = .home
            Task {
                await viewModel.didOpenViaControlCenter(id: value)
            }
        }
        .onOpenURL { url in
            tabManager.selectedTab = .home
            Task {
                await viewModel.didOpenViaDeepLink(url)
            }
        }
        .sheet(isPresented: $showReferrals) {
            NavigationStack {
                ReferralView(
                    viewModel: referralViewModel,
                    referralDataStorage: persistenceManager
                )
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
            VStack {
                Button {
                    showReferrals = true
                } label: {
                    ReferralBanner(emoji: "👯🤩👯‍♂️")
                }
                .padding(.bottom, 20)
                .padding(.horizontal)
                .transition(.scale.combined(with: .opacity))
                .buttonStyle(.plain)
                
                placeholder
            }
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
                        
                        ShareLink(items: [shareableImage.url])
                    }
                }
        }
    }
    
    private var selectionButtons: some View {
        VStack(spacing: 16) {
            if ProcessInfo.processInfo.isiOSAppOnMac {
                PrimaryButton(title: "Select From Files") {
                    Task { await viewModel.attemptToImportFile() }
                }
                Button("Select Photos") {
                    Task { await viewModel.selectPhotos() }
                }
                .font(.headline)
            } else {
                PrimaryButton(title: "Select Photos") {
                    Task { await viewModel.selectPhotos() }
                }
                Button("Select From Files") {
                    Task { await viewModel.attemptToImportFile() }
                }
                .font(.headline)
            }
        }
        .disabled(viewModel.isLoading)
        .padding([.bottom, .horizontal])
    }
    
    @ViewBuilder
    private var placeholderContextButton: some View {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            Button {
                Task { await viewModel.selectPhotos() }
            } label: {
                Label("Select Photos", systemImage: "photo")
            }
        } else {
            Button {
                Task { await viewModel.attemptToImportFile() }
            } label: {
                Label("Select From Files", systemImage: "doc")
            }
        }
    }
    
    private var placeholder: some View {
        VStack(spacing: 30) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .contextMenu { placeholderContextButton }
                .frame(maxWidth: 200)
                .contentShape(
                    .hoverEffect,
                    .rect(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )
                .hoverEffect()
                .foregroundColor(.secondary)
                .onTapGesture {
                    if ProcessInfo.processInfo.isiOSAppOnMac {
                        Task { await viewModel.attemptToImportFile() }
                    } else {
                        Task { await viewModel.selectPhotos() }
                    }
                }
        }
        .padding()
        .frame(maxHeight: .infinity)
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
        
        
        ShareLink(items: [shareableImage.url])
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
                
                ShareLink(items: shareableImages.map(\.url))
            }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView(viewModel: HomeViewModel(photoLibraryManager: .empty(status: .authorized)))
        }
    }
}
#endif

