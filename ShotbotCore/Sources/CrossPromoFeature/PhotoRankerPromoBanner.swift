//
//  PhotoRankerPromoBanner.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 1/17/25.
//

import SwiftUI
import SwiftTools

public struct PhotoRankerPromoBanner: View {
    public init() {}

    public var body: some View {
        HStack {
            Image("PhotoRanker128", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(widthAndHeight: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading) {
                Text("Photo Ranker")
                    .font(.headline)
                Text("Find your best photos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .multilineTextAlignment(.center)
        .background(.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

#Preview {
    PhotoRankerPromoBanner()
}
