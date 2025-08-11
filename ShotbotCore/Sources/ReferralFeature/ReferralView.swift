//
//  ReferralView.swift
//  Shotbot
//

import SwiftUI
import ReferralService
import Persistence

public struct ReferralView: View {
    @StateObject private var viewModel = ReferralViewModel()
    @EnvironmentObject private var persistenceManager: PersistenceManager
    
    public init() { }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                
                if viewModel.hasReferralCodes {
                    myReferralCodeSection
                }
                
                if persistenceManager.canEnterReferralCode {
                    useReferralCodeSection
                        .transition(.scale.combined(with: .opacity))
                }
                
                redemptionSection
            }
            .disabled(viewModel.isLoading)
            .padding()
        }
        .navigationTitle("Referrals")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.blue)
                        
                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $viewModel.showingCodeInput) {
            ReferralCodeInputView()
                .environmentObject(viewModel)
        }
        .alert("Success!", isPresented: $viewModel.showingSuccessMessage) {
            Button("OK") {
                viewModel.dismissSuccessMessage()
            }
        } message: {
            Text(viewModel.successMessage)
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error.failureReason ?? error.localizedDescription)
            }
        }
    }
    
    private var creditText: String {
        persistenceManager.creditBalance == 1 ? "credit" : "credits"
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Refer & Earn")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Share Shotbot with friends and earn rewards together!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var myReferralCodeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "qrcode")
                    .foregroundColor(.blue)
                
                Text("Your Referral \(viewModel.referralCodes.count > 1 ? "Codes" : "Code")")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if viewModel.referralCodes.count > 1 {
                    NavigationLink(destination: AllReferralCodesView()
                        .environmentObject(viewModel)
                    ) {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            if let code = viewModel.primaryReferralCode {
                ReferralCodeCard(code: code)
            } else {
                NoReferralCodeCard()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var useReferralCodeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                
                Text("Use a Referral Code")
                    .font(.headline)
                
                Spacer()
            }
            
            Text("Enter a friend's referral code to get started with benefits!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                viewModel.showingCodeInput = true
            } label: {
                HStack {
                    Image(systemName: "keyboard")
                    Text("Enter Referral Code")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(maxWidth: 300)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isUsingCode)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var redemptionSection: some View {
        NavigationLink(destination: RewardsView()
            .environmentObject(viewModel)
            .environmentObject(persistenceManager)
        ) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.blue)
                    
                    Text("Redeem Rewards")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(persistenceManager.creditBalance.formatted())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text(creditText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Redeem your credits for extra screenshots and custom codes!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ReferralView()
            .environmentObject(PersistenceManager.shared)
    }
}
