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

enum BackgroundType: String, CaseIterable, Identifiable {
    var id: Self { self }
    case solidColor
    case linearGradient
    case angularGradient
    case radialGradient
    case image
}


public struct HomeView: View {
    @StateObject var manager = AppIntentManager.shared
    @StateObject var viewModel = HomeViewModel()
    @EnvironmentObject var tabManager: TabManager
    @Environment(\.scenePhase) var scenePhase
    @State private var color = Color.blue
    @State private var backgroundType: BackgroundType = .angularGradient
    @Environment(\.displayScale) var displayScale
    @State private var renderedImage = Image(systemName: "photo")
    @State private var padding: CGFloat = 0

    // MARK: - Initializer
    
    public init(viewModel: HomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            picker
            
            Picker("Background Type", selection: $backgroundType) {
                ForEach(BackgroundType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            Slider(value: $padding, in: 0...100)
            
            ColorPicker("Color", selection: $color)
            
            mainContent
            selectionButtons
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
        .onChange(of: backgroundType) { _, _ in
            Task {
                await render()
            }
        }
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
            placeholder
        case .individualImages(let shareableImages):
            individualImagesView(shareableImages)
        case .combinedImages(let shareableImage):
            Image(uiImage: shareableImage.framedScreenshot)
                .resizable()
                .scaledToFit()
                .padding(padding)
                .border(Color.red)
                .background {
                    backgroundView
                        .animation(.default, value: backgroundType)
                        .animation(.default, value: color)
                        .border(Color.blue)
                }
                .border(Color.green)
                .draggable(renderedImage)
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
    
    private var selectionButtons: some View {
        VStack(spacing: 16) {
            if ProcessInfo.processInfo.isiOSAppOnMac {
                PrimaryButton(title: "Select From Files") {
                    viewModel.attemptToImportFile()
                }
                Button("Select Photos") {
                    viewModel.selectPhotos()
                }
                .font(.headline)
            } else {
                PrimaryButton(title: "Select Photos") {
                    viewModel.selectPhotos()
                }
                Button("Select From Files") {
                    viewModel.attemptToImportFile()
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
                viewModel.selectPhotos()
            } label: {
                Label("Select Photos", systemImage: "photo")
            }
        } else {
            Button {
                viewModel.attemptToImportFile()
            } label: {
                Label("Select From Files", systemImage: "doc")
            }
        }
    }
    
    @ViewBuilder
     private var backgroundView: some View {
         switch backgroundType {
         case .image:
             Image(uiImage: viewModel.imageResults.originalScreenshots.first!)
                 .resizable()
                 .scaledToFill()
                 .blur(radius: 20)
         case .solidColor:
             color
         case .linearGradient:
             Rectangle().fill(color.gradient)
         case .radialGradient:
             RadialGradient(
                 gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple]),
                 center: .center,
                 startRadius: 50,
                 endRadius: 1000
             )
         case .angularGradient:
             AngularGradient(
                 gradient: Gradient(
                     colors: [
                         .red,
                         .yellow,
                         .green,
                         .blue,
                         .purple,
                         .red
                     ]
                 ),
                 center: .center
             )
         }
     }
    
    private var placeholder: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .contextMenu { placeholderContextButton }
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
                if ProcessInfo.processInfo.isiOSAppOnMac {
                    viewModel.attemptToImportFile()
                } else {
                    viewModel.selectPhotos()
                }
            }
    }
    
    private func tabView(shareableImages: [ShareableImage]) -> some View {
        TabView {
            ForEach(shareableImages) { shareableImage in
                rendered(shareableImage)
                    .contextMenu {
                        contextMenu(shareableImage: shareableImage)
                    }
//                    .padding([.horizontal, .top])
//                    .padding(.bottom, 40)
                    .draggable(renderedImage)
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
    
    fileprivate func renderedV1(_ shareableImage: ShareableImage) -> some View {
        backgroundView
            .clipShape(Square())
            .overlay {
                Image(uiImage: shareableImage.framedScreenshot)
                    .resizable()
                    .scaledToFit()
                //            .padding()
            }
    }
    
    fileprivate func rendered(_ shareableImage: ShareableImage) -> some View {
        backgroundView
            .aspectRatio(1, contentMode: .fit)
            .animation(.default, value: backgroundType)
            .animation(.default, value: color)
            .cornerRadius(20)
            .overlay {
                GeometryReader { proxy in
                    Image(uiImage: shareableImage.framedScreenshot)
                        .resizable()
                        .scaledToFit()
                        .frame(height: proxy.size.height * 0.9)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
            }
            .padding(padding)
    }
    
    fileprivate func renderedV2(_ shareableImage: ShareableImage) -> some View {
        GeometryReader { proxy in
            let squareSize = min(proxy.size.width, proxy.size.height)
            let imageSize = max(0, squareSize * 0.9)
            
            ZStack {
                backgroundView
                    .frame(width: squareSize, height: squareSize)
                    .animation(.default, value: backgroundType)
                    .animation(.default, value: color)
                    .border(Color.red)
                    .cornerRadius(20)
                
                Image(uiImage: shareableImage.framedScreenshot)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize, height: imageSize)
                    .border(Color.green)
                let _ = print(imageSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .border(Color.yellow)
        .padding()
        .border(Color.blue)
    }
    
    @MainActor func render() async {
        try! await Task.sleep(for: .seconds(1))
        let view = rendered(viewModel.imageResults.individual.first!)
            .frame(widthAndHeight: 3000)
        let renderer = ImageRenderer(content: view)
        
        // make sure and use the correct display scale for this device
        renderer.scale = displayScale
        
        if let uiImage = renderer.uiImage {
            renderedImage = Image(uiImage: uiImage)
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
                        .draggable(renderedImage)
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
            HomeView(viewModel: HomeViewModel(photoLibraryManager: .empty(status: .authorized)))
        }
    }
}
#endif




struct Square: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height) // Ensures it's always a square
        let originX = rect.midX - side / 2
        let originY = rect.midY - side / 2
        
        return Path { path in
            path.addRect(CGRect(x: originX, y: originY, width: side, height: side))
        }
    }
}

struct SquareView: View {
    var body: some View {
        Square()
            .fill(Color.blue)
            .frame(width: 100, height: 100) // Example size
    }
}

struct ContentView: View {
    var body: some View {
        SquareView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
