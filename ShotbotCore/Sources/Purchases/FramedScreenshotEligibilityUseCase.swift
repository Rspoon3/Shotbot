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
    
    public enum SaveReason: Sendable {
        case cannotSave
        case subscribed
        case free
        case rewards(usedCount: Int)
        case debugFalse
        case debugTrue
        
        public var canSave: Bool {
            switch self {
            case .cannotSave, .debugFalse: return false
            default : return true
            }
        }
        
        public var rewardedScreenShotsCount: Int? {
            switch self {
            case .rewards(usedCount: let count):
                return count
            default:
                return nil
            }
        }
    }
    
    // MARK: - Initializer
    
    public init(
        persistenceManager: PersistenceManager = PersistenceManager.shared,
        referralService: ReferralService = ReferralService()
    ) {
        self.persistenceManager = persistenceManager
        self.referralService = referralService
    }
    
    public func canProceedWithPhotoSelection() async -> Bool {
#if DEBUG
        switch persistenceManager.subscriptionOverride {
        case .alwaysFalse:
            return false
        case .alwaysTrue:
            return true
        case .appStore:
            return await canProceedWithPhotoSelectionAppStore()
        }
#else
        return await canProceedWithPhotoSelectionAppStore
#endif
    }
    
    private func canProceedWithPhotoSelectionAppStore() async -> Bool {
        if persistenceManager.isSubscribed { return true }
        
        if persistenceManager.freeFramedScreenshotsRemaining > 0 {
            return true
        }
        
        // Check for extra screenshots from referral rewards
        guard let countResponse = try? await referralService.getRewardCount(rewardId: "extra_screenshots") else {
            return false
        }
        
        return countResponse.availableQuantity > 0
    }
    
    /// Checks if user can save framed screenshots
    /// - Parameter screenshotCount: The number of screenshots attempting to be framed
    /// - Returns: A `SaveReason` enum value indicating the eligibility status:
    ///   - `.subscribed`: User has an active subscription
    ///   - `.free`: User is within the free usage limit (30 screenshots)
    ///   - `.rewards(usedCount:)`: User can use referral rewards, with count of rewards to be used in this session
    ///   - `.cannotSave`: User cannot save (no subscription, exceeded free limit, no rewards)
    ///   - `.debugTrue`/`.debugFalse`: Debug-only override values
    public func canSaveFramedScreenshot(screenshotCount: Int) async -> SaveReason {
#if DEBUG
        switch persistenceManager.subscriptionOverride {
        case .alwaysFalse:
            return .debugTrue
        case .alwaysTrue:
            return .debugTrue
        case .appStore:
            return await canSaveFramedScreenshotAppStore(screenshotCount: screenshotCount)
        }
#else
        return await canSaveFramedScreenshotAppStore(screenshotCount: screenshotCount)
#endif
    }
    
    private func canSaveFramedScreenshotAppStore(screenshotCount: Int) async -> SaveReason {
        // Check subscription status first
        if persistenceManager.isSubscribed {
            return .subscribed
        }
        
        // Check if we have enough free screenshots remaining
        if persistenceManager.freeFramedScreenshotsRemaining >= screenshotCount {
            return .free
        }
        
        // Check for extra screenshots from referral rewards
        guard let countResponse = try? await referralService.getRewardCount(rewardId: "extra_screenshots") else {
            return .cannotSave
        }
        
        // Check if we have enough rewards for the requested screenshots beyond the free limit
        let neededBeyondFreeLimit = screenshotCount - persistenceManager.freeFramedScreenshotsRemaining
        if countResponse.availableQuantity >= neededBeyondFreeLimit {
            // Return how many reward screenshots will be used in this session
            return .rewards(usedCount: neededBeyondFreeLimit)
        } else {
            return .cannotSave
        }
    }
    
    
    /// Attempts to consume extra screenshot rewards
    /// - Parameter amount: The number of extra screenshots to consume (default: 1)
    public func consumeExtraScreenshot(amount: Int) async throws {
        let response = try await referralService.consumeReward("extra_screenshots", amount: amount)
        persistenceManager.creditBalance = response.balance
    }
}

