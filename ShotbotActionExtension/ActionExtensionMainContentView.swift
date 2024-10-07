//
//  ActionExtensionMainContentView.swift
//  ShotbotActionExtension
//
//  Created by Ricky on 9/24/24.
//

import SwiftUI
import Models

struct ActionExtensionMainContentView: View {
    @ObservedObject var viewModel: ActionExtensionViewModel

    var body: some View {
        VStack {
            if viewModel.hasMultipleImages {
                Picker("Image Type", selection: $viewModel.imageType) {
                    ForEach(ImageType.allCases) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            
            switch viewModel.imageType {
            case .individual:
                if let shareableImages = viewModel.shareableImages {
                    Group {
                        if viewModel.showGridView {
                            gridView(shareableImages: shareableImages)
                        } else {
                            tabView(shareableImages: shareableImages)
                        }
                    }
                } else {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                }
            case .combined:
                if let shareableCombinedImage = viewModel.shareableCombinedImage {
                    image(uiImage: shareableCombinedImage.framedScreenshot)
                        .overlay {
                            if viewModel.isReversingImages {
                                ProgressView()
                            }
                        }
                } else {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }
        
    // MARK: - Private
        
    private func image(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: .infinity)
            .padding([.horizontal, .top])
            .padding(.bottom, 40)
    }
    
    private func tabView(shareableImages: [ShareableImage]) -> some View {
        TabView {
            ForEach(shareableImages) { shareableImage in
                image(uiImage: shareableImage.framedScreenshot)
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
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
//Comente
