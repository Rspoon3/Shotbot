//
//  ShotbotApp.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/23/23.
//

import SwiftUI
import AppFeature
import RevenueCat
import Purchases
import Persistence
import MediaManager
import AppIntents
import OSLog
import Photos
import Models
import ReferralFeature
@preconcurrency import ReferralService

#if canImport(WidgetKit)
import WidgetKit
#endif

@main
struct ShotbotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegateAdaptor.self) private var appDelegate
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var tabManager = TabManager()
    @Environment(\.scenePhase) private var scenePhase

    private let logger = Logger(category: "ShotbotApp")
    private let referralChecker = ReferralChecker()
    private let notificaitonManager = NotificationManager()
    private let autoSaveMigration = MigrateAutoSaveSettingsUseCase()

    init() {
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: "appl_VOYNmwadBWEHBTYKlnZludJLwEX")

        // Migrate legacy autosave settings
        autoSaveMigration.migrate()
    }
    
    var body: some Scene {
        WindowGroup {
            AppTabNavigation()
                .environmentObject(persistenceManager)
                .environmentObject(purchaseManager)
                .environmentObject(tabManager)
                .task {
                    await purchaseManager.fetchOfferings()
                    await notificaitonManager.registerStoredTokenOnAppLaunch()
                    await updateCanEnterReferralCode()
                    
                    guard persistenceManager.hasShownNotificationPermission else { return }
                    await referralChecker.checkForUnnotifiedReferralsAndCreditBalance()
                }
                .onAppear {
                    performLogging()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                persistenceManager.numberOfActivations += 1
            case .background:
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
                #endif
            default:
                break
            }
        }
    #if os(visionOS)
        .defaultSize(
            width: 600,
            height: 800
        )
    #endif
    }
    
    private func updateCanEnterReferralCode() async {
        guard persistenceManager.canEnterReferralCode else {
            logger.info("Can't enter referral code. No need to check BE.")
            return
        }
        
        do {
            let referralService = ReferralService()
            let canEnter = try await referralService.canEnterReferralCode()
            persistenceManager.canEnterReferralCode = canEnter
            logger.info("Can enter referral code status: \(canEnter, privacy: .public)")
        } catch {
            logger.error("Error checking referral service for canEnterReferralCode: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private func performLogging() {
        let systemVersion = UIDevice.current.systemVersion
        let version = Bundle.appVersion ?? "N/A"
        let build = Bundle.appBuild ?? "N/A"
        let name = UIDevice.current.name
        
        logger.notice("OS Version: \(systemVersion, privacy: .public). App Version: \(version, privacy: .public) (\(build, privacy: .public)).")
        logger.notice("Device name: \(name, privacy: .public).")
        
        var screenSize: CGRect?
        
#if os(visionOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            screenSize = windowScene.coordinateSpace.bounds
        }
#else
        screenSize = UIScreen.main.bounds
#endif
        
        guard let screenSize else { return }
        let screenWidth = screenSize.width.formatted()
        let screenHeight = screenSize.height.formatted()
        logger.notice("Screen width: \(screenWidth, privacy: .public). Screen height: \(screenHeight, privacy: .public).")
    }
}


