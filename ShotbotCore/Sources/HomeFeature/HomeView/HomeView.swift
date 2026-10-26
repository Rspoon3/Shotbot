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
import CrossPromoFeature

public struct HomeView: View {
    @StateObject var manager = AppIntentManager.shared
    @StateObject var viewModel = HomeViewModel()
    @EnvironmentObject private var persistenceManager: PersistenceManager
    @EnvironmentObject var tabManager: TabManager
    @Environment(\.scenePhase) var scenePhase
    @State private var showReferrals = false
    @State private var showNotificationPermission = false
    @StateObject private var referralViewModel = ReferralViewModel()
    private let crossPromoStore = CrossPromoStore()

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
        .frame(maxWidth: .infinity)
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
                .fullScreenCover(isPresented: $showNotificationPermission) {
                    NotificationPermissionView(isPresented: $showNotificationPermission)
                }
                .onAppear {
                    guard !persistenceManager.hasShownNotificationPermission else { return }
                    showNotificationPermission = true
                    persistenceManager.hasShownNotificationPermission = true
                }
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
            ToolbarItem(placement: .primaryAction) {
                if !viewModel.styleOptions.isEmpty {
                    styleMenu
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                if viewModel.canShowClearButton {
                    if #available(iOS 26.0, *) {
                        Button(role: .destructive) {
                            viewModel.clearContent()
                        }.tint(.red)
                    } else {
                        Button("Clear", role: .destructive) {
                            viewModel.clearContent()
                        }.foregroundColor(.red)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $viewModel.isImportingFile,
            allowedContentTypes: [.image, .png, .jpeg],
            allowsMultipleSelection: true
        ) { viewModel.fileImportCompletion(result: $0) }
        .sheet(isPresented: $viewModel.showDeviceDisambiguation) {
            if let screenshot = viewModel.disambiguationScreenshot {
                DeviceDisambiguationView(
                    devices: viewModel.ambiguousDeviceOptions,
                    screenshot: screenshot
                ) { device in
                    viewModel.didSelectDisambiguatedDevice(device)
                }
            }
        }
    }
    
    /// A toolbar menu for choosing the frame color and view of the devices in the current screenshots.
    ///
    /// Only devices whose frame has more than one color or view are listed. A device gets a color section, and a view
    /// section for each of its screens that has views. With several choices, each section is named after what it
    /// changes.
    private var styleMenu: some View {
        Menu {
            ForEach(viewModel.styleOptions) { option in
                if option.hasColors {
                    Section(sectionTitle("color", for: option)) {
                        Picker(option.deviceName, selection: colorSelection(for: option)) {
                            ForEach(option.colors, id: \.self) { color in
                                Text(color)
                                    .tag(color)
                            }
                        }
                    }
                }

                ForEach(option.screens) { screen in
                    Section(sectionTitle("view", for: option, screen: screen)) {
                        Picker(option.deviceName, selection: viewSelection(for: screen)) {
                            ForEach(screen.views, id: \.self) { view in
                                Text(view)
                                    .tag(view)
                            }
                        }
                    }
                }
            }
        } label: {
            Label("Frame Style", symbol: .paintpalette)
        }
    }

    /// "Color" or "View", with the device and screen in front of it when there is more than one of them.
    private func sectionTitle(_ title: String, for option: DeviceStyleOption, screen: DeviceStyleOption.Screen? = nil) -> String {
        var parts = [String]()

        if viewModel.styleOptions.count > 1 {
            parts.append(option.deviceName)
        }

        if let screenName = screen?.screenName, option.screens.count > 1 {
            parts.append(screenName)
        }

        guard !parts.isEmpty else { return title.capitalized }

        return (parts + [title]).joined(separator: " ")
    }

    private func colorSelection(for option: DeviceStyleOption) -> Binding<String> {
        Binding {
            option.selectedColor ?? ""
        } set: { color in
            Task(priority: .userInitiated) {
                await viewModel.didSelectColor(color, forDeviceNamed: option.deviceName)
            }
        }
    }

    private func viewSelection(for screen: DeviceStyleOption.Screen) -> Binding<String> {
        Binding {
            screen.selectedView
        } set: { view in
            Task(priority: .userInitiated) {
                await viewModel.didSelectView(view, forViewKey: screen.viewKey)
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
            VStack {
                if persistenceManager.referralBannerCount < 10 {
                    Button {
                        showReferrals = true
                    } label: {
                        ReferralBanner(emoji: "👯📸👯‍♂️")
                            .frame(maxWidth: 400)
                    }
                    .padding(.bottom, 20)
                    .padding(.horizontal)
                    .transition(.scale.combined(with: .opacity))
                    .buttonStyle(.plain)
                    .onFirstAppear {
                        persistenceManager.referralBannerCount += 1
                    }
                } else if crossPromoStore.shouldShowBanner() {
                    PhotoRankerBannerButton(store: crossPromoStore)
                }

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
        
        imageStyleMenu(for: shareableImage)
    }
    
    /// Frame color and view choices for just this screenshot, so screenshots can be mixed and matched.
    ///
    /// Only shown for individual images when there is more than one. A choice made here wins over the toolbar menu's choice
    /// for this screenshot until it is cleared.
    @ViewBuilder
    private func imageStyleMenu(for shareableImage: ShareableImage) -> some View {
        if let option = viewModel.styleOption(forImageWithID: shareableImage.id) {
            Menu {
                if option.hasColors {
                    Section("Color") {
                        Picker("Color", selection: imageColorSelection(for: shareableImage, option: option)) {
                            ForEach(option.colors, id: \.self) { color in
                                Text(color)
                                    .tag(color)
                            }
                        }
                    }
                }
                
                ForEach(option.screens) { screen in
                    Section("View") {
                        Picker("View", selection: imageViewSelection(for: shareableImage, screen: screen)) {
                            ForEach(screen.views, id: \.self) { view in
                                Text(view)
                                    .tag(view)
                            }
                        }
                    }
                }
                
                if option.isCustomized {
                    Button {
                        Task(priority: .userInitiated) {
                            await viewModel.resetStyle(forImageWithID: shareableImage.id)
                        }
                    } label: {
                        Label("Use Toolbar Choice", symbol: .arrowCounterclockwise)
                    }
                }
            } label: {
                Label("Frame Style", symbol: .paintpalette)
            }
        }
    }
    
    private func imageColorSelection(for shareableImage: ShareableImage, option: DeviceStyleOption) -> Binding<String> {
        Binding {
            option.selectedColor ?? ""
        } set: { color in
            Task(priority: .userInitiated) {
                await viewModel.didSelectColor(color, forImageWithID: shareableImage.id)
            }
        }
    }
    
    private func imageViewSelection(for shareableImage: ShareableImage, screen: DeviceStyleOption.Screen) -> Binding<String> {
        Binding {
            screen.selectedView
        } set: { view in
            Task(priority: .userInitiated) {
                await viewModel.didSelectView(view, forImageWithID: shareableImage.id)
            }
        }
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

