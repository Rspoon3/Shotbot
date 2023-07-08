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
import OSLog

@main
struct ShotbotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegateAdaptor.self) private var appDelegate
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.scenePhase) private var scenePhase
    private let logger = Logger(category: "ShotbotApp")
    
    init() {
        Purchases.logLevel = .info
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: "appl_VOYNmwadBWEHBTYKlnZludJLwEX")
                .build()
        )
    }
    
    var body: some Scene {
        WindowGroup {
            AppTabNavigation()
                .environmentObject(persistenceManager)
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.fetchOfferings()
                }
                .onAppear {
                    performLogging()
                }
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            persistenceManager.numberOfActivations += 1
        }
    }
    
    private func performLogging() {
        let systemVersion = UIDevice.current.systemVersion
        let version = Bundle.appVersion ?? "N/A"
        let build = Bundle.appBuild ?? "N/A"
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width.formatted()
        let screenHeight = screenSize.height.formatted()
        let name = UIDevice.current.name
        
        logger.notice("OS Version: \(systemVersion). App Version: \(version) (\(build)).")
        logger.notice("Screen width: \(screenWidth). Screen height: \(screenHeight).")
        logger.notice("Device name: \(name).")
    }
}

class AppDelegateAdaptor: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PersistenceManager.shared.numberOfLaunches += 1
        return true
    }
}
