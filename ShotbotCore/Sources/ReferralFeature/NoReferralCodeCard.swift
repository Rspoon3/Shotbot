//
//  NoReferralCodeCard.swift
//  Shotbot
//

import SwiftUI

struct NoReferralCodeCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "qrcode.viewfinder")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No referral code yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Your referral code will appear here once generated")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}