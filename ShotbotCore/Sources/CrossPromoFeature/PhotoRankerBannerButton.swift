//
//  PhotoRankerBannerButton.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 1/17/25.
//

import SwiftUI
import SwiftTools

public struct PhotoRankerBannerButton: View {
    @Environment(\.openURL) private var openURL
    private let crossPromoStore: CrossPromoStore

    public init(crossPromoStore: CrossPromoStore) {
        self.crossPromoStore = crossPromoStore
    }

    public var body: some View {
        Button {
            openURL(.photoRanker)
        } label: {
            PhotoRankerPromoBanner()
                .frame(maxWidth: 400)
        }
        .padding(.bottom, 20)
        .padding(.horizontal)
        .transition(.scale.combined(with: .opacity))
        .buttonStyle(.plain)
        .onFirstAppear {
            crossPromoStore.recordBannerShown()
        }
    }
}

#Preview {
    PhotoRankerBannerButton(crossPromoStore: CrossPromoStore())
        .padding()
}
