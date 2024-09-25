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
                if let shareableImage = viewModel.shareableImages {
                    TabView {
                        ForEach(shareableImage) { shareableImage in
                            image(uiImage: shareableImage.framedScreenshot)
                        }
                    }
                    .tabViewStyle(.page)
                    .onAppear {
                        let appearance = UIPageControl.appearance()
                        appearance.currentPageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.75)
                        appearance.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.33)
                    }
                } else {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                }
            case .combined:
                if let shareableCombinedImage = viewModel.shareableCombinedImage {
                    image(uiImage: shareableCombinedImage.framedScreenshot)
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
}
