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
import SwiftData

#if canImport(WidgetKit)
import WidgetKit
#endif

@main
struct ShotbotApp: App {
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var tabManager = TabManager()
    @Environment(\.scenePhase) private var scenePhase

    private let logger = Logger(category: "ShotbotApp")
    private let modelContainer: ModelContainer
    
    init() {
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: "appl_VOYNmwadBWEHBTYKlnZludJLwEX")
        
        do {
            let schema = Schema([SDAnalyticEvent.self, SDAppVersion.self])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppTabNavigation()
                .environmentObject(persistenceManager)
                .environmentObject(purchaseManager)
                .environmentObject(tabManager)
                .modelContainer(modelContainer)
                .onAppear {
                    performLogging()
                }
                .task {
                    await purchaseManager.fetchOfferings()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                persistenceManager.numberOfActivations += 1
                recordAppActivation()
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
        
        if let screenSize {
            let screenWidth = screenSize.width.formatted()
            let screenHeight = screenSize.height.formatted()
            logger.notice("Screen width: \(screenWidth, privacy: .public). Screen height: \(screenHeight, privacy: .public).")
        }
        
        // Record app launch and increment counter
        persistenceManager.numberOfLaunches += 1
        recordAppLaunch()
        
        // Log analytics counts using Swift Data
        do {
            let context = modelContainer.mainContext
            let launchCount = try SDAnalyticEvent.totalCount(for: .appLaunch, modelContext: context)
            let activationCount = try SDAnalyticEvent.totalCount(for: .appActivation, modelContext: context)
            let frameCreationCount = try SDAnalyticEvent.totalCount(for: .deviceFrameCreation, modelContext: context)
            
            logger.notice("numberOfLaunches: \(launchCount.formatted(), privacy: .public)")
            logger.notice("numberOfActivations: \(activationCount.formatted(), privacy: .public)")
            logger.notice("deviceFrameCreations: \(frameCreationCount.formatted(), privacy: .public)")
        } catch {
            logger.warning("Failed to fetch launch/activation counts: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Analytics Recording
    
    private func recordAppLaunch() {
        let context = modelContainer.mainContext
        let appVersion = SDAppVersion()
        let analyticEvent = SDAnalyticEvent(event: .appLaunch, appVersion: appVersion)
        
        context.insert(appVersion)
        context.insert(analyticEvent)
        
        do {
            try context.save()
            logger.info("Successfully saved app launch event")
        } catch {
            logger.error("Failed to save app launch event: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private func recordAppActivation() {
        let context = modelContainer.mainContext
        let appVersion = SDAppVersion()
        let analyticEvent = SDAnalyticEvent(event: .appActivation, appVersion: appVersion)
        
        context.insert(appVersion)
        context.insert(analyticEvent)
        
        do {
            try context.save()
            logger.info("Successfully saved app activation event")
        } catch {
            logger.error("Failed to save app activation event: \(error.localizedDescription, privacy: .public)")
        }
    }
}

