//
//  ActionExtensionView.swift
//  ShotbotActionExtension
//
//  Created by Richard Witherspoon on 4/30/23.
//

import SwiftUI
import Models

struct ActionExtensionView: View {
    @ObservedObject var viewModel: ActionExtensionViewModel
    
    var body: some View {
        NavigationView {
            bodyItem
                .task { await viewModel.loadAttachments() }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel"){
                            viewModel.cancelButtonTapped()
                        }
                    }
                    
                    if let urls = viewModel.sharableURLs {
                        ToolbarItem(placement: .primaryAction) {
                            ShareLink(items: urls)
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var bodyItem: some View {
        if viewModel.canSaveFramedScreenshot {
            mainContent
        } else {
            Text("Shotbot Pro Required")
                .font(.largeTitle)
        }
    }
    
    private var mainContent: some View {
        VStack {
            if (viewModel.shareableImages?.count ?? 0) > 1 {
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
                            Image(uiImage: shareableImage.framedScreenshot)
                                .resizable()
                                .scaledToFit()
                                .padding([.horizontal, .top])
                                .padding(.bottom, 40)
                        }
                    }
                    .tabViewStyle(.page)
                    .onAppear {
                        let appearance = UIPageControl.appearance()
                        appearance.currentPageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.75)
                        appearance.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.33)
                    }
                }
                else {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                }
            case .combined:
                if let shareableImage = viewModel.shareableCombinedImage {
                    Image(uiImage: shareableImage.framedScreenshot)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: .infinity)
                        .padding([.horizontal, .top])
                        .padding(.bottom, 40)
                } else {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

