//
//  FramedScreenshotEligibilityUseCase.swift
//  Shotbot
//

import Foundation
import Persistence
import ReferralFeature
import ReferralService

/// Use case responsible for determining if a user can create framed screenshots
/// Handles subscription status, free usage limits, and extra screenshots from referral rewards
@MainActor
public struct FramedScreenshotEligibilityUseCase: Sendable {
    private let persistenceManager: PersistenceManager
    private let referralService: ReferralService
    
    public init(
        persistenceManager: PersistenceManager,
        referralService: ReferralService
    ) {
        self.persistenceManager = persistenceManager
        self.referralService = referralService
    }
    
    /// Checks if user can save framed screenshots
    /// - Parameter screenshotCount: The number of screenshots attempting to be framed
    /// Returns true if user is subscribed, has free screenshots remaining for the requested amount, or has extra screenshot rewards
    public func canSaveFramedScreenshot(screenshotCount: Int) async -> Bool {
#if DEBUG
        switch persistenceManager.subscriptionOverride {
        case .alwaysFalse:
            return false
        case .alwaysTrue:
            return true
        case .appStore:
            return await canSaveFramedScreenshotAppStore(screenshotCount: screenshotCount)
        }
#else
        return await canSaveFramedScreenshotAppStore(screenshotCount: screenshotCount)
#endif
    }
    
    private func canSaveFramedScreenshotAppStore(screenshotCount: Int) async -> Bool {
        // Check subscription status first
        if persistenceManager.isSubscribed {
            return true
        }
        
        // Check if adding the requested screenshots would exceed the free limit
        let totalAfterFraming = persistenceManager.deviceFrameCreations + screenshotCount
        if totalAfterFraming <= 30 {
            return true
        }
        
        // Check for extra screenshots from referral rewards
        guard let countResponse = try? await referralService.getRewardCount(rewardId: "extra_screenshots") else {
            return false
        }
        
        // Check if we have enough rewards for the requested screenshots
        let neededBeyondFreeLimit = totalAfterFraming - 30
        return countResponse.availableQuantity >= neededBeyondFreeLimit
    }
    
    
    /// Attempts to consume extra screenshot rewards
    /// - Parameter amount: The number of extra screenshots to consume (default: 1)
    /// Returns true if successful, false if no rewards available or error occurred
    @discardableResult
    public func consumeExtraScreenshot(amount: Int = 1) async throws -> Bool {
        let response = try await referralService.consumeReward("extra_screenshots", amount: amount)
        persistenceManager.creditBalance = response.balance
        return true
    }
}

