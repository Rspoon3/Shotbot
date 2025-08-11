//
//  RewardOptionCard.swift
//  Shotbot
//

import SwiftUI
import ReferralService

struct RewardOptionCard: View {
    let reward: AvailablePurchase
    let canAfford: Bool
    let onRedeem: () async -> Void
    
    @State private var isRedeeming = false
    
    private var iconName: String {
        switch reward.rewardType {
        case "extra_screenshots":
            return "photo.stack"
        case "custom_code":
            return "star.fill"
        default:
            return "gift"
        }
    }
    
    private var iconColor: Color {
        switch reward.rewardType {
        case "extra_screenshots":
            return .blue
        case "custom_code":
            return .yellow
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(reward.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(reward.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("\(reward.cost)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(reward.cost == 1 ? "credit" : "credits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    Task {
                        isRedeeming = true
                        await onRedeem()
                        isRedeeming = false
                    }
                } label: {
                    if isRedeeming {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 70)
                    } else {
                        Text("Redeem")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 70)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!canAfford || isRedeeming || reward.quantityRemaining == 0)
            }
            
            if let quantityRemaining = reward.quantityRemaining, quantityRemaining > 0 {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(quantityRemaining) remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}