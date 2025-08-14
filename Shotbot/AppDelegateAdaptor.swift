//
//  AppDelegateAdaptor.swift
//  Shotbot
//
//  Created by Ricky Witherspoon on 8/11/25.
//

import UIKit
import ReferralFeature
@preconcurrency import ReferralService
import Persistence
import OSLog

final class AppDelegateAdaptor: NSObject, UIApplicationDelegate {
    private let logger = Logger(category: AppDelegateAdaptor.self)
    private let notificationManager = NotificationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PersistenceManager.shared.numberOfLaunches += 1
        return true
    }
    
    // MARK: - Remote Notification Registration
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            await notificationManager.handleDeviceTokenRegistration(deviceToken)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.info("Failed to register for remote notifications: \(error.localizedDescription, privacy: .public)")
    }
}
