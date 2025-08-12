//
//  RewardsView.swift
//  Shotbot
//

import SwiftUI
import ReferralService
import Persistence

struct RewardsView: View {
    @ObservedObject var viewModel: ReferralViewModel
    @EnvironmentObject private var persistenceManager: PersistenceManager
    @Environment(\.dismiss) private var dismiss
    
    private let isModal: Bool
    
    init(
        viewModel: ReferralViewModel,
        isModal: Bool = false
    ) {
        self.viewModel = viewModel
        self.isModal = isModal
    }
    
    private var creditText: String {
        persistenceManager.creditBalance == 1 ? "credit" : "credits"
    }
    
    private func creditText(for amount: Int) -> String {
        amount == 1 ? "credit" : "credits"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                if persistenceManager.creditBalance > 0 {
                    availableCreditsSection
                } else {
                    noCreditsSection
                }
                
                redemptionOptionsSection
                
                if !viewModel.userRewards.isEmpty {
                    AvailableRewardsView(userRewards: viewModel.userRewards)
                }
            }
            .padding()
        }
        .navigationTitle("Rewards")
        .navigationBarTitleDisplayMode(.inline)
        .background {
            Color(.secondarySystemBackground).ignoresSafeArea(.all)
        }
        .task {
            guard viewModel.availablePurchases.isEmpty else { return }
            await viewModel.loadData()
        }
        .toolbar {
            if isModal {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Referral Rewards")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Redeem your credits for amazing rewards!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var availableCreditsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.blue)
                
                Text("Available Credits")
                    .font(.headline)
                
                Spacer()
                
                Text("\(persistenceManager.creditBalance)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text("You have \(persistenceManager.creditBalance) \(creditText) to spend")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var noCreditsSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No credits yet")
                .font(.headline)
            
            Text("Share your referral code with friends to earn credits")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: ReferralView()) {
                Text("View Referral Code")
                    .fontWeight(.semibold)
                    .frame(maxWidth: 300)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var redemptionOptionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(.blue)
                
                Text("Available Rewards")
                    .font(.headline)
                
                Spacer()
            }
            
            if viewModel.isLoadingRewards {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(height: 100)
            } else if viewModel.availablePurchases.isEmpty {
                Text("No rewards available at this time")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(height: 100)
            } else {
                RedemptionOptionsView(viewModel: viewModel)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
