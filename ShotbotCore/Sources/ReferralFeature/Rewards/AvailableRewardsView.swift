//
//  AvailableRewardsView.swift
//  Shotbot
//

import SwiftUI
import ReferralService

struct AvailableRewardsView: View {
    let userRewards: [UserReward]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.blue)
                
                Text("Your Rewards")
                    .font(.headline)
                
                Spacer()
            }
            
            if userRewards.isEmpty {
                Text("No rewards earned yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(userRewards, id: \.id) { reward in
                    UserRewardRow(reward: reward)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct UserRewardRow: View {
    let reward: UserReward
    
    private var iconName: String {
        switch reward.purchaseType {
        case "extra_screenshots":
            return "photo.stack"
        case "custom_code":
            return "star.fill"
        default:
            return "gift"
        }
    }
    
    private var iconColor: Color {
        switch reward.purchaseType {
        case "extra_screenshots":
            return .blue
        case "custom_code":
            return .yellow
        default:
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
                .background(iconColor.opacity(0.1))
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reward.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let redeemedAt = reward.redeemedAt {
                    Text("Redeemed \(redeemedAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if reward.isActive {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}