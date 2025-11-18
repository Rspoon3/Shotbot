//
//  PhotoRankerSettingsRow.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 1/17/25.
//

import SwiftUI

public struct PhotoRankerSettingsRow: View {
    @Environment(\.openURL) private var openURL

    public init() {}

    public var body: some View {
        Button {
            openURL(.photoRanker)
        } label: {
            Label {
                VStack(alignment: .leading) {
                    Text("Photo Ranker")
                    Text("Find your best photos")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } icon: {
                Image("PhotoRanker128", bundle: .module)
                    .resizable()
                    .frame(width: 29, height: 29)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    Form {
        Section {
            PhotoRankerSettingsRow()
        }
    }
}
