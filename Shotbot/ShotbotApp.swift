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
    @UIApplicationDelegateAdaptor(AppDelegateAdaptor.self) private var appDelegate
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
            let schema = Schema([SDAnalyticEvent.self])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Set the shared model container for the app delegate to use
//        AppDelegateAdaptor.shared = modelContainer
    }
    
    var body: some Scene {
        WindowGroup {
            AppTabNavigation()
                .environmentObject(persistenceManager)
                .environmentObject(purchaseManager)
                .environmentObject(tabManager)
                .modelContainer(modelContainer)
                .task {
                    await purchaseManager.fetchOfferings()
                    await performLogging()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                persistenceManager.numberOfActivations += 1
                recordActivation()
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
        
        // Log analytics counts using Swift Data
        let context = modelContainer.mainContext
        
        do {
            let launches = try SDAnalyticEvent.totalCount(for: .appLaunch, modelContext: context)
            let activations = try SDAnalyticEvent.totalCount(for: .appActivation, modelContext: context)
            let frameCreations = try SDAnalyticEvent.totalCount(for: .deviceFrameCreation, modelContext: context)
                        
            logger.notice("numberOfLaunches: \(launches.formatted(), privacy: .public)")
            logger.notice("numberOfActivations: \(activations.formatted(), privacy: .public)")
            logger.notice("deviceFrameCreations: \(frameCreations.formatted(), privacy: .public)")
        } catch {
            logger.warning("Failed to fetch launch/activation counts: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private func recordActivation() {
        let context = modelContainer.mainContext
        let appVersion = SDAppVersion()
        let analyticEvent = SDAnalyticEvent(event: .appActivation, appVersion: appVersion)
        
        context.insert(appVersion)
        context.insert(analyticEvent)
        
        do {
            try context.save()
        } catch {
            logger.error("Failed to save activation event: \(error.localizedDescription, privacy: .public)")
        }
    }
}

final class AppDelegateAdaptor: NSObject, UIApplicationDelegate {
//    let modelContainer: ModelContainer!
//    
//    init(modelContainer: ModelContainer!) {
//        self.modelContainer = modelContainer
//    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PersistenceManager.shared.numberOfLaunches += 1
        recordLaunch()
        return true
    }
    
    private func recordLaunch() {
//        do {
//            let context = modelContainer.mainContext
//            let appVersion = SDAppVersion()
//            let analyticEvent = SDAnalyticEvent(event: .appLaunch, appVersion: appVersion)
//            
//            context.insert(appVersion)
//            context.insert(analyticEvent)
//            
//            try context.save()
//        } catch {
//            print("Failed to save launch event: \(error)")
//        }
    }
}
