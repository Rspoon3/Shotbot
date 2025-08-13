//
//  ReferralViewModel.swift
//  Shotbot
//

import Foundation
import SwiftUI
import OSLog
import ReferralService

@MainActor
public class ReferralViewModel: ObservableObject {
    
    @Published var currentUser: ReferralUser?
    @Published var referralCodes: [ReferralCode] = []
    @Published var codeRules: CodeRules?
    @Published var userReferrals: [Referral] = []
    
    @Published var isLoading = false
    @Published var isLoadingCodes = false
    @Published var isUsingCode = false
    @Published var isRedeemingReward = false
    
    @Published var error: ReferralNetworkingError?
    @Published var showingError = false
    
    @Published var showingShareSheet = false
    @Published var showingCodeInput = false
    @Published var showingSuccessMessage = false
    @Published var successMessage = ""
    
    @Published var referralCodeInput = ""
    
    @Published var availablePurchases: [AvailablePurchase] = []
    @Published var userRewards: [UserReward] = []
    @Published var isLoadingRewards = false
    
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    private let referralService = ReferralService()
    private let logger = Logger(subsystem: "com.shotbot.referral", category: "ReferralViewModel")
    
    var codeValidator: ReferralCodeValidator {
        return ReferralCodeValidator(codeRules: codeRules)
    }
    
    var primaryReferralCode: ReferralCode? {
        referralCodes.first { $0.isActive }
    }
    
    var hasReferralCodes: Bool {
        !referralCodes.isEmpty
    }
    
    func loadData(options: ReferralDataOptions = .all) async {
        guard !isLoading else { return }
        
        logger.info("Loading referral data: \(options.description, privacy: .public)")
        
        error = nil
        withAnimation {
            isLoading = true
        }
        
        await withTaskGroup(of: Void.self) { group in
            if options.contains(.codes) {
                group.addTask { await self.loadReferralCodes() }
            }
            if options.contains(.rules) {
                group.addTask { await self.loadCodeRules() }
            }
            if options.contains(.rewards) {
                group.addTask { await self.loadAvailableRewards() }
            }
        }
        
        logger.info("Successfully loaded referral data: \(options.description, privacy: .public)")

        withAnimation {
            isLoading = false
        }
    }
    
    private func loadReferralCodes() async {
        guard !isLoadingCodes else { return }
        
        isLoadingCodes = true
        defer { isLoadingCodes = false }
        
        do {
            referralCodes = try await referralService.getUserReferralCodes()
            logger.debug("Loaded \(self.referralCodes.count) referral codes")
        } catch {
            logger.error("Failed to load referral codes: \(error.localizedDescription)")
            await handleError(error)
        }
    }
    
    private func loadCodeRules() async {
        codeRules = await referralService.getCodeRules()
    }
    
    @discardableResult
    func useReferralCode(_ code: String) async -> Int? {
        guard !isUsingCode else { return nil }
        
        logger.info("Using referral code: \(code)")
        error = nil
        isUsingCode = true
        defer { isUsingCode = false }
        
        do {
            let validation = await referralService.validateReferralCodeUsage(code)
            guard validation.isValid else {
                throw validation.error ?? ReferralNetworkingError.invalidReferralCode
            }
            
            let result = try await referralService.useReferralCode(code)
            
            userReferrals.append(result.referral)
            referralCodeInput = ""
            
            logger.info("Successfully used referral code")
            
            return result.creditBalance
        } catch {
            logger.error("Failed to use referral code: \(error.localizedDescription)")
            if let referralError = error as? ReferralNetworkingError {
                self.error = referralError
            } else {
                self.error = ReferralNetworkingError.unknown(error.localizedDescription)
            }
            return nil
        }
    }
    
    func shareReferralCode() {
        guard let primaryReferralCode else {
            logger.warning("No primary referral code available to share")
            return
        }
        
        logger.info("Sharing referral code: \(primaryReferralCode.code)")
        showingShareSheet = true
    }
    
    @discardableResult
    func createCustomCode(_ customCode: String) async -> [ReferralCode]? {
        guard !isLoading else { return nil }
        
        logger.info("Creating custom referral code: \(customCode)")
        error = nil
        withAnimation {
            isLoading = true
        }
        defer { 
            withAnimation {
                isLoading = false
            }
        }
        
        do {
            let updatedCodes = try await referralService.createCustomCode(customCode)
            
            referralCodes = updatedCodes
            
            successMessage = "Custom code '\(customCode.uppercased())' created successfully!"
            showingSuccessMessage = true
            feedbackGenerator.notificationOccurred(.success)
            
            logger.info("Successfully created custom referral code")
            
            return updatedCodes
        } catch {
            feedbackGenerator.notificationOccurred(.error)
            logger.error("Failed to create custom referral code: \(error.localizedDescription)")
            await handleError(error)
            return nil
        }
    }
    
    private func loadAvailableRewards() async {
        guard !isLoadingRewards else { return }
        
        isLoadingRewards = true
        defer { isLoadingRewards = false }
        
        do {
            let response = try await referralService.getRewards()
            availablePurchases = response.availablePurchases
            
            withAnimation {
                userRewards = response.userRewards
            }
            
            logger.debug("Loaded \(response.availablePurchases.count.formatted()) available rewards")
        } catch {
            logger.error("Failed to load rewards: \(error.localizedDescription)")
            await handleError(error)
        }
    }
    
    @discardableResult
    func redeemReward(_ reward: AvailablePurchase) async -> Int? {
        guard !isRedeemingReward else { return nil }
        
        logger.info("Redeeming reward: \(reward.id)")
        error = nil
        isRedeemingReward = true
        defer { isRedeemingReward = false }
        
        do {
            let response = try await referralService.spendCredits(
                reward.cost,
                rewardId: reward.id
            )
            
            await loadAvailableRewards()
            
            successMessage = "Successfully redeemed \(reward.title)!"
            showingSuccessMessage = true
            feedbackGenerator.notificationOccurred(.success)
            
            logger.info("Successfully redeemed reward")
            
            return response.balance
        } catch {
            logger.error("Failed to redeem reward: \(error.localizedDescription)")
            await handleError(error)
            return nil
        }
    }
    
    private func handleError(_ error: Error) async {
        if let referralError = error as? ReferralNetworkingError {
            self.error = referralError
            guard referralError.shouldDisplay else { return }
            showingError = true
        } else {
            self.error = ReferralNetworkingError.unknown(error.localizedDescription)
            showingError = true
        }
    }
    
    func clearError() {
        error = nil
        showingError = false
    }
    
    func dismissSuccessMessage() {
        showingSuccessMessage = false
        successMessage = ""
    }
}
