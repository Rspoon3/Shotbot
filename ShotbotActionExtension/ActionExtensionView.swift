//
//  ActionExtensionView.swift
//  ShotbotActionExtension
//
//  Created by Richard Witherspoon on 4/30/23.
//

import SwiftUI

struct ActionExtensionView: View {
    @ObservedObject var viewModel: ActionExtensionViewModel
    
    var body: some View {
        NavigationView {
            bodyItem
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel"){
                            viewModel.cancelButtonTapped()
                        }
                    }
                    
                    if let shareableImages = viewModel.shareableImages {
                        ToolbarItem(placement: .primaryAction) {
                            ShareLink(items: shareableImages.map(\.url))
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
            } else {
                ProgressView()
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
