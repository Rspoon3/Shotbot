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
    
    var body: some View {
        HStack {
            Image(systemName: reward.symbolString)
                .foregroundColor(reward.availableQuantity == 0 ? .secondary : .blue)
                .frame(width: 20)
            
            Text(reward.title)
                .font(.body)
                .foregroundColor(reward.availableQuantity == 0 ? .secondary : .primary)
            
            Spacer()
            
            Text(reward.availableQuantity.formatted())
                .font(.headline)
                .contentTransition(.numericText(value: Double(reward.availableQuantity)))
                .foregroundColor(reward.availableQuantity == 0 ? .secondary : .blue)
        }
        .padding(.vertical, 4)
    }
}