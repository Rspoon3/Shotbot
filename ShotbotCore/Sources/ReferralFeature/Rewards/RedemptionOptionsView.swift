//
//  RedemptionOptionsView.swift
//  Shotbot
//

import SwiftUI
import ReferralService
import Persistence
import OSLog

struct RedemptionOptionsView: View {
    @ObservedObject var viewModel: ReferralViewModel
    @EnvironmentObject private var persistenceManager: PersistenceManager
    @State private var selectedOption: AvailablePurchase?
    @State private var isRedeeming = false
    private let logger = Logger(subsystem: "com.shotbot.referral", category: "RedemptionOptionsView")
    
    private var redeemButtonIsDisabled: Bool {
        !canRedeem || isRedeeming || persistenceManager.creditBalance <= 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoadingRewards {
                ProgressView("Loading rewards...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if viewModel.availablePurchases.isEmpty {
                Text("No rewards available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(viewModel.availablePurchases) { option in
                    RewardOptionCard(
                        option: option,
                        isSelected: selectedOption?.id == option.id,
                        canAfford: canAfford(option)
                    ) {
                        selectedOption = option
                    }
                }
            }
            
            if let selectedOption {
                redeemButton(selectedOption)
                
                if !canRedeem {
                    let cost = selectedOption.cost
                    Text("Need \(cost) \(creditText(for: cost)) to redeem this reward")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear(perform: autoSelectFirstAvailableReward)
        .onChange(of: viewModel.availablePurchases) { _, newPurchases in
            if selectedOption == nil && !newPurchases.isEmpty {
                selectedOption = newPurchases.first
            }
        }
    }
    
    private func redeemButton(_ selectedOption: AvailablePurchase) -> some View {
        Button {
            Task {
                await handleRewardAction(selectedOption)
            }
        } label: {
            HStack {
                if isRedeeming {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "gift")
                }
                
                Text(isRedeeming ? "Redeeming..." : "Redeem \(selectedOption.title)")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(redeemButtonIsDisabled)
    }
    
    private func creditText(for amount: Int) -> String {
        amount == 1 ? "credit" : "credits"
    }
    
    private func autoSelectFirstAvailableReward() {
        guard selectedOption == nil && !viewModel.availablePurchases.isEmpty else { return }
        selectedOption = viewModel.availablePurchases.first
    }
    
    private func canAfford(_ option: AvailablePurchase) -> Bool {
        return persistenceManager.creditBalance >= option.cost
    }
    
    private var canRedeem: Bool {
        guard let selectedOption else { return false }
        return canAfford(selectedOption)
    }
    
    private func handleRewardAction(_ selectedOption: AvailablePurchase) async {
        switch selectedOption.action {
        case "redeem":
            await redeemReward()
        default:
            logger.error("Reward action not supported: \(selectedOption.action ?? "nil")")
        }
    }
    
    private func redeemReward() async {
        guard let selectedOption else { return }
        
        isRedeeming = true
        defer { isRedeeming = false }
        
        guard let newBalance = await viewModel.redeemReward(selectedOption) else { return }
        
        withAnimation {
            persistenceManager.creditBalance = newBalance
        }
    }
}
