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
import Shortcuts
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
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            persistenceManager.numberOfActivations += 1
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
        
        guard let screenSize else { return }
        let screenWidth = screenSize.width.formatted()
        let screenHeight = screenSize.height.formatted()
        logger.notice("Screen width: \(screenWidth, privacy: .public). Screen height: \(screenHeight, privacy: .public).")
    }
}

extension ShotbotApp: AppIntentsPackage {
    static var includedPackages: [AppIntentsPackage.Type] = [
        ShotbotAppIntentsPackage.self
    ]
}

class AppDelegateAdaptor: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PersistenceManager.shared.numberOfLaunches += 1
        return true
    }
}



//
//struct LibraryAutoShortCuts: AppShortcutsProvider {
//
//    static var appShortcuts: [AppShortcut] {
//        AppShortcut(
//            intent: AddBook(),
//            phrases: ["Start Meditation"],
//            shortTitle: "dfhgh",
//            systemImageName: "ant"
//        )
//    }
//}
//


import SwiftUI
import AppIntents
import CollectionConcurrencyKit
import OSLog
import AppIntents
import Models


struct AddBook: AppIntent {
    // The name of the action in Shortcuts
    static var title: LocalizedStringResource = "Add Book"
    
    // Description of the action in Shortcuts
    // Category name allows you to group actions - shown when tapping on an app in the Shortcuts library
    static var description: IntentDescription = IntentDescription(
"""
Add a new book to your collection.

A preview of the new book is optionally shown as a Snippet after the action has run.
""", categoryName: "Editing")
    
    // String input options allow you to set the keyboard type, capitalization and more
    @Parameter(title: "Title", description: "The title of the new book", inputOptions: String.IntentInputOptions(capitalizationType: .words), requestValueDialog: IntentDialog("What is the title of the book?"))
    var title: String

    @Parameter(title: "Author", description: "The author of the new book's name", inputOptions: String.IntentInputOptions(capitalizationType: .words), requestValueDialog: IntentDialog("What is the author of the book's name?"))
    var author: String
    
    // Optionally accept an image to set as the book's cover. We can define the types of files that are accepted
    @Parameter(title: "Cover Image", description: "An optional image of the book's cover", supportedTypeIdentifiers: ["public.image"], requestValueDialog: IntentDialog("What image should be used as the cover of the book?"))
    var coverImage: IntentFile?

    @Parameter(title: "Read", description: "Toggle on if you have read the book", default: false, requestValueDialog: IntentDialog("Have you read the book?"))
    var isRead: Bool
    
    @Parameter(title: "Date Published", description: "The date the book was published", requestValueDialog: IntentDialog("What date was the book published?"))
    var datePublished: Date
    
    // How the summary will appear in the shortcut action.
    // More parameters are included below the fold in the trailing closure. In Shortcuts, they are listed in the reverse order they are listed here
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) by \(\.$author) with \(\.$coverImage)") {
            \.$datePublished
            \.$isRead
        }
    }

    @MainActor // <-- include if the code needs to be run on the main thread
    func perform() async throws -> some ReturnsValue<Int> {
        
        var image: UIImage? = nil
        if let imageData = coverImage?.data {
            image = UIImage(data: imageData)
        }
        
        return .result(value: 4)
    }
}
