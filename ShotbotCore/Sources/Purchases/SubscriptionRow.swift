//
//  SubscriptionRow.swift
//  Cinematic
//
//  Created by Richard Witherspoon on 10/23/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct SubscriptionRow: View {
    let symbol: String
    let color: Color
    let headline: String
    let subheadline: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 14){
            Image(systemName: symbol)
                .imageScale(.large)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 0){
                Text(headline)
                    .font(.headline)
                Text(subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    struct SubscriptionRow_Previews: PreviewProvider {
        static var previews: some View {
            SubscriptionRow(
                symbol: "star",
                color: .blue,
                headline: "Unlimited Collections",
                subheadline: "Create unlimited collections of movies and cast members."
            )
        }
    }
}
