//
//  NotificationManager.swift
//  Plate-O
//
//  Created by Ricky Witherspoon on 7/17/25.
//

import Foundation
import NotificationCenter
import OSLog
import SwiftTools
import ReferralService

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    private let logger = Logger(category: NotificationManager.self)
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
        
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Public
    
    func requestNotificationPermissions() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                logger.info("Notification permissions granted")
                await UIApplication.shared.registerForRemoteNotifications()
            } else {
                logger.warning("Notification permissions denied")
            }
        } catch {
            logger.error("Failed to request notification permissions: \(error)")
        }
    }
    
    func shouldRequestPermission() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .notDetermined
    }
    
    func sendReferralNotification(count: Int) async {
        do {
            // Request permission if needed
            let settings = await notificationCenter.notificationSettings()
            
            if settings.authorizationStatus == .notDetermined {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
                guard granted else {
                    logger.warning("Notification permission not granted")
                    return
                }
            }
           
            let request = createNotificationRequest(count: count)
            try await notificationCenter.add(request)
            logger.info("Referral notification sent for \(count) referrals")
        } catch {
            logger.error("Failed to send referral notification: \(error)")
        }
    }
    
    func setBadgeNumber(to count: Int) async {
        do {
            let settings = await notificationCenter.notificationSettings()
            
            if settings.authorizationStatus == .notDetermined {
                await requestNotificationPermissions()
            }
            
            try await notificationCenter.setBadgeCount(count)
            logger.info("App badge set to: \(count)")
        } catch {
            logger.error("Failed to set badge count: \(error)")
        }
    }
    
    // MARK: - Device Token Management
    
    func registerStoredTokenOnAppLaunch() async {
        guard let deviceToken = userDefaults.string(forKey: "deviceToken") else {
            logger.info("No stored device token found on app launch")
            return
        }
        
        logger.info("Registering stored device token on app launch: ....\(String(deviceToken.suffix(8)))")
        await registerDeviceTokenWithBackend(deviceToken)
    }
    
    func handleDeviceTokenRegistration(_ deviceToken: Data) async {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Get stored token from UserDefaults
        let storedToken = userDefaults.string(forKey: "deviceToken")
        let hasTokenChanged = storedToken != nil && storedToken != tokenString
        
        if hasTokenChanged {
            logger.info("Device token changed, will deactivate old token")
        }
        
        userDefaults.set(tokenString, forKey: "deviceToken")
        logger.info("Device token stored: \(tokenString.prefix(8), privacy: .public)")
        
        await handleTokenRefresh(
            newToken: tokenString,
            oldToken: storedToken,
            hasChanged: hasTokenChanged
        )
    }
    
    private func handleTokenRefresh(newToken: String, oldToken: String?, hasChanged: Bool) async {
        if hasChanged, let oldToken {
            logger.info("Deactivating old device token: ....\(String(oldToken.suffix(8)))")
            await deactivateSpecificDeviceToken(oldToken)
        }
        
        await registerDeviceTokenWithBackend(newToken)
    }
    
    private func registerDeviceTokenWithBackend(_ token: String) async {
        logger.info("Registering device token with backend: ....\(String(token.suffix(8)))")
        
        do {
            // Create ReferralService instance following your app's pattern
            let referralService = ReferralService()
            let success = try await referralService.registerDeviceToken(token, deviceType: "ios")
            
            if success {
                logger.info("Device token registered successfully")
            } else {
                logger.warning("Failed to register device token")
            }
        } catch {
            logger.error("Error registering device token: \(error)")
        }
    }
    
    private func deactivateSpecificDeviceToken(_ token: String) async {
        logger.info("Deactivating device token: ....\(String(token.suffix(8)))")
        
        do {
            let referralService = ReferralService()
            let success = try await referralService.deactivateDeviceToken(token)
            
            if success {
                logger.info("Device token deactivated successfully")
            } else {
                logger.warning("Failed to deactivate device token")
            }
        } catch {
            logger.error("Error deactivating device token: \(error)")
        }
    }
    
    private func createNotificationRequest(count: Int) -> UNNotificationRequest {
        // Create notification content
        let content = UNMutableNotificationContent()
        let bodyStart = count == 1 ? "Someone" : "\(count) people"
        let body = "\(bodyStart) redeemed your referral code! You have rewards waiting."
        content.title = "Referral Redeemed!"
        content.sound = .default
        content.body = body
        
        // Create trigger (immediate delivery)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        return UNNotificationRequest(
            identifier: "referral-redeemed-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
