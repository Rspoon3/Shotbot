//
//  InfiniteScroller.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/8/23.
//

import SwiftUI

struct InfiniteScroller<Content: View>: View {
    let duration: TimeInterval
    let contentWidth: CGFloat
    let content: (() -> Content)
    
    @State private var xOffset: CGFloat = 0
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                content()
                content()
            }
            .offset(x: xOffset, y: 0)
        }
        .disabled(true)
        .task {
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                xOffset = -contentWidth - 20 * 5
            }
        }
    }
}

struct InfiniteScroller_Previews: PreviewProvider {
    static var previews: some View {
        InfiniteScroller(duration: 3,  contentWidth: 150 * 5) {
            ForEach(1..<6, id: \.self) { i in
                Image("Preview\(i)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
            }
        }
    }
}
