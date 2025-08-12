//
//  ReferralChecker.swift
//  Plate-O
//
//  Created by Ricky Witherspoon on 7/17/25.
//

import Foundation
import ReferralService
import OSLog
import Persistence

/// A service responsible for checking referral statuses and managing notifications.
///
/// `ReferralChecker` coordinates between the referral service and notification system
/// to ensure users are notified of new referrals and their credit balance is kept up to date.
public struct ReferralChecker: Sendable {
    private let logger = Logger(category: ReferralChecker.self)
    private let referralService = ReferralService()
    private let notificationManager = NotificationManager()
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public
    
    /// Checks for unnotified referrals and updates the user's credit balance.
    ///
    /// This method performs two main tasks:
    /// 1. Fetches any referrals that haven't been notified to the user
    /// 2. Retrieves the current credit balance
    ///
    /// If unnotified referrals are found, a notification is sent to the user.
    /// The app badge is updated to reflect the current credit balance.
    ///
    /// - Note: This method must be called on the main actor as it updates UI-related state.
    @MainActor
    public func checkForUnnotifiedReferralsAndCreditBalance() async {
        do {
            async let unnotifiedReferralsResponse = referralService.getUnnotifiedReferrals()
            async let creditBalanceResponse = referralService.getCreditBalance()
            
            let (unnotifiedReferrals, creditBalance) = try await (unnotifiedReferralsResponse, creditBalanceResponse)
            
            logger.info("Found \(unnotifiedReferrals.count) unnotified referrals")
            logger.info("Current credit balance: \(creditBalance.balance)")
            
            PersistenceManager.shared.creditBalance = creditBalance.balance
            
            if unnotifiedReferrals.count > 0 {
                await notificationManager.sendReferralNotification(count: unnotifiedReferrals.count)
            }
            
            await notificationManager.setBadgeNumber(to: creditBalance.balance)
        } catch {
            logger.error("Failed to check for unnotified referrals and credit balance: \(error)")
        }
    }
}
