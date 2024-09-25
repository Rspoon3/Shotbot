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
            ActionExtensionMainContentView(viewModel: viewModel)
        } else {
            Text("Shotbot Pro Required")
                .font(.largeTitle)
        }
    }
}

