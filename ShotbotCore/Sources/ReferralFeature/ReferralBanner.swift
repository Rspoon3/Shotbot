//
//  ReferralBanner.swift
//  Shotbot
//

import SwiftUI

public struct ReferralBanner: View {
    @State private var scale: Double = 1
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Text("Refer & Earn!")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Share Shotbot with friends to unlock extra screenshots and custom codes")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .scaleEffect(scale)
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: scale)
        .task {
            try? await Task.sleep(for: .seconds(1))
            scale = 0.97
        }
    }
}

#Preview {
    ReferralBanner()
        .padding()
}