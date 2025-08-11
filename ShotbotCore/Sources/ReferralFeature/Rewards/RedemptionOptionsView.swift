//
//  RedemptionOptionsView.swift
//  Shotbot
//

import SwiftUI
import ReferralService

struct RedemptionOptionsView: View {
    @EnvironmentObject private var viewModel: ReferralViewModel
    @EnvironmentObject private var persistenceManager: PersistenceManager
    
    private var extraScreenshotRewards: [AvailablePurchase] {
        viewModel.availablePurchases.filter { $0.rewardType == "extra_screenshots" }
    }
    
    private var customCodeRewards: [AvailablePurchase] {
        viewModel.availablePurchases.filter { $0.rewardType == "custom_code" }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if !extraScreenshotRewards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Extra Screenshots", systemImage: "photo.stack")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(extraScreenshotRewards, id: \.id) { reward in
                        RewardOptionCard(
                            reward: reward,
                            canAfford: persistenceManager.creditBalance >= reward.cost,
                            onRedeem: {
                                await redeemReward(reward)
                            }
                        )
                    }
                }
            }
            
            if !customCodeRewards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Custom Referral Codes", systemImage: "star.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(customCodeRewards, id: \.id) { reward in
                        RewardOptionCard(
                            reward: reward,
                            canAfford: persistenceManager.creditBalance >= reward.cost,
                            onRedeem: {
                                await redeemReward(reward)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func redeemReward(_ reward: AvailablePurchase) async {
        let newBalance = await viewModel.redeemReward(reward)
        
        if let balance = newBalance {
            persistenceManager.creditBalance = balance
            
            if reward.rewardType == "extra_screenshots" {
                persistenceManager.extraScreenshots += reward.value ?? 0
            } else if reward.rewardType == "custom_code" {
                persistenceManager.canCreateCustomCode = true
            }
        }
    }
}