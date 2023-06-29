//
//  PurchaseView.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/4/23.
//

import SwiftUI

public struct PurchaseView: View {
    @StateObject private var viewModel: PurchaseViewModel
    @Environment(\.openURL) var openURL
    @State var xOffset: CGFloat = 0
    private let aspectRatio = 300.0/609.0
    private let images = [
        "beach",
        "jetta",
        "taylorSwift",
        "calendar",
        "oakley"
    ]
    
    // MARK: - Initializer
    
    public init(purchaseManager: PurchaseManaging = PurchaseManager.shared) {
        let vm = PurchaseViewModel(purchaseManager: purchaseManager)
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack {
            explainers
            Spacer()
            imageScroller
            Spacer()
            bottomButtons
        }
        .navigationTitle("Shotbot Pro")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Something went wrong."))
        }
        .overlay {
            if viewModel.userAction != nil {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.all, 20)
                    .background(
                        .thinMaterial,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }
        }
    }
    
    private var explainers: some View {
        VStack(alignment: .leading, spacing: 30) {
            SubscriptionRow(
                symbol: "photo",
                color: .blue,
                headline: "Unlimited Screenshots",
                subheadline: "Removes the 30 screenshot limit"
            )
            
            SubscriptionRow(
                symbol: "heart",
                color: .red,
                headline: "Support Development",
                subheadline: "Help bring new devices, features, and improvements to "//\(Bundle.settings.appTitle!)"
            )
        }
        .padding()
    }
    
    private var imageScroller: some View {
        GeometryReader { geo in
            let scaledHeight = geo.size.height * 0.8
            let contentHeight = min(500, scaledHeight)
            let contentWidth = contentHeight * aspectRatio
            let duration = contentWidth * 0.5
            
            InfiniteScroller(
                duration: duration,
                contentWidth: contentWidth * CGFloat(images.count)
            ) {
                ForEach(images, id: \.self) { image in
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: contentHeight)
                }
            }
            .position(
                x: geo.frame(in: .local).midX,
                y: geo.frame(in: .local).midY
            )
        }
    }
    
    private var bottomButtons: some View {
        VStack {
            Button {
                viewModel.purchase()
            } label:{
                VStack {
                    if viewModel.isSubscribed {
                        Text("Subscription Active")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.vertical, 6)
                    } else {
                        Text("Try it free")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(viewModel.annulPriceText)
                            .font(.caption)
                    }
                }
                .frame(maxWidth: 300)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(viewModel.buttonDisabled)

            HStack {
                Button("Privacy & Terms") {
                    openURL(.privacyPolicy)
                }
                
                Button("Restore") {
                    viewModel.restorePurchase()
                }
            }
            .font(.caption2)
        }
        .padding(.bottom)
    }
}

struct PurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PurchaseView(purchaseManager: MockPurchaseManager())
        }
    }
}
