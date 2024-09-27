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
                .task { await viewModel.loadAttachments() }
                .alert(error: $viewModel.error) {
                    viewModel.cancelButtonTapped()
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel"){
                            viewModel.cancelButtonTapped()
                        }.tint(.red)
                    }
                    
                    ToolbarItemGroup(placement: .primaryAction) {
                        if viewModel.showReverseImageButton {
                            Button {
                                Task {
                                    await viewModel.reverseImages()
                                }
                            } label: {
                                Label("Reverse Images", systemImage: "arrow.left.arrow.right")
                            }
                            .disabled(viewModel.isReversingImages)
                        }
                        
                        if let name = viewModel.viewTypeImageName {
                            Button {
                                viewModel.toggleIndividualViewType()
                            } label: {
                                Label("Individual View Type", systemImage: name)
                            }
                        }

                        if let urls = viewModel.sharableURLs {
                            ShareLink(items: urls)
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var bodyItem: some View {
        if viewModel.canSaveFramedScreenshot {
            ActionExtensionMainContentView(viewModel: viewModel)
        } else {
            Text("Shotbot Pro Required")
                .font(.largeTitle)
        }
    }
}

