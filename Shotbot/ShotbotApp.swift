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

@main
struct ShotbotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegateAdaptor.self) private var appDelegate
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        Purchases.logLevel = .debug
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
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            persistenceManager.numberOfActivations += 1
        }
    }
}

class AppDelegateAdaptor: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PersistenceManager.shared.numberOfLaunches += 1
        return true
    }
}
