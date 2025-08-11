//
//  PersistenceManager.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/23/23.
//

import SwiftUI
import Models
import OSLog
import SwiftTools

@MainActor
public final class PersistenceManager: ObservableObject, PersistenceManaging, Sendable {
    public static let shared = PersistenceManager()
    private let logger = Logger(category: PersistenceManager.self)

    private init(){
        logger.notice("isSubscribed: \(self.isSubscribed, privacy: .public)")
        logger.notice("deviceFrameCreations: \(self.deviceFrameCreations.formatted(), privacy: .public)")
        logger.notice("numberOfLaunches: \(self.numberOfLaunches.formatted(), privacy: .public)")
        logger.notice("numberOfActivations: \(self.numberOfActivations.formatted(), privacy: .public)")
    }
    
    private var canSaveFramedScreenshotAppStore: Bool {
        isSubscribed || deviceFrameCreations <= 30
    }
    
    public var canSaveFramedScreenshot: Bool {
#if DEBUG
        switch subscriptionOverride {
        case .alwaysFalse:
            return false
        case .alwaysTrue:
            return true
        case .appStore:
            return canSaveFramedScreenshotAppStore
        }
#else
        canSaveFramedScreenshotAppStore
#endif
    }
    
    public var freeFramedScreenshotsRemaining: Int {
        max(0, (30 - deviceFrameCreations))
    }
    
    @AppStorage("isSubscribed", store: .shared)
    public var isSubscribed = false
    
    @AppStorage("autoCopy")
    public var autoCopy: Bool = false
    
    @AppStorage("autoSaveToFiles")
    public var autoSaveToFiles: Bool = false
    
    @AppStorage("autoSaveToPhotos")
    public var autoSaveToPhotos: Bool = false
    
    @AppStorage("autoDeleteScreenshots")
    public var autoDeleteScreenshots: Bool = false
    
    @AppStorage("defaultHomeTab", store: .shared)
    public var defaultHomeTab: ImageType = .individual
    
    @AppStorage("defaultHomeView", store: .shared)
    public var defaultHomeView: HomeViewType = .tabbed
    
    @AppStorage("clearImagesOnAppBackground")
    public var clearImagesOnAppBackground: Bool = false
    
    @AppStorage("imageSelectionType")
    public var imageSelectionType: ImageSelectionType = .all
    
    @AppStorage("imageQuality", store: .shared)
    public var imageQuality: ImageQuality = .original
    
    @iCloudKeyValueStore("numberOfLaunches")
    public var numberOfLaunches: Int = 0
    
    @iCloudKeyValueStore("numberOfActivations")
    public var numberOfActivations: Int = 0
    
    @iCloudKeyValueStore("deviceFrameCreations")
    public var deviceFrameCreations: Int = 0
    
    @iCloudKeyValueStore("lastReviewPromptDate")
    public var lastReviewPromptDate: Date? = nil
    
    @AppStorage("creditBalance")
    public var creditBalance: Int = 0
    
    @AppStorage("canEnterReferralCode")
    public var canEnterReferralCode: Bool = true
    
    @AppStorage("extraScreenshots")
    public var extraScreenshots: Int = 0
    
    @AppStorage("canCreateCustomCode")
    public var canCreateCustomCode: Bool = false
    
    
#if DEBUG
    public enum SubscriptionOverrideMethod: String, CaseIterable, Identifiable {
        case alwaysTrue = "True"
        case alwaysFalse = "False"
        case appStore = "App Store"
        
        public var id: String { rawValue }
    }
    
    @AppStorage("subscriptionOverride", store: .shared)
    public var subscriptionOverride: SubscriptionOverrideMethod = .appStore
#endif
    
    public func setLastReviewPromptDateToNow() {
        lastReviewPromptDate = .now
    }
}

public class MockPersistenceManager: PersistenceManaging {
    public var lastReviewPromptDate: Date?
    public var canSaveFramedScreenshot: Bool = false
    public var isSubscribed: Bool = false
    public var numberOfLaunches: Int = 0
    public var numberOfActivations: Int = 0
    public var deviceFrameCreations: Int = 0
    public var autoCopy: Bool = false
    public var autoSaveToFiles: Bool = false
    public var autoSaveToPhotos: Bool = false
    public var autoDeleteScreenshots: Bool = false
    public var defaultHomeTab: ImageType = .individual
    public var defaultHomeView: HomeViewType = .tabbed
    public var clearImagesOnAppBackground: Bool = false
    public var imageSelectionType: ImageSelectionType = .all
    public var imageQuality: ImageQuality = .original
    public var creditBalance: Int = 0
    public var canEnterReferralCode: Bool = true
    public var extraScreenshots: Int = 0
    public var canCreateCustomCode: Bool = false
    
    public init() {}

    public func reset() {
        lastReviewPromptDate = nil
        canSaveFramedScreenshot = false
        isSubscribed = false
        autoCopy = false
        autoSaveToFiles = false
        autoSaveToPhotos = false
        autoDeleteScreenshots = false
        defaultHomeTab = .individual
        defaultHomeView = .tabbed
        clearImagesOnAppBackground = false
        numberOfLaunches = 0
        numberOfActivations = 0
        deviceFrameCreations = 0
        imageSelectionType = .all
        imageQuality = .original
        creditBalance = 0
        canEnterReferralCode = true
        extraScreenshots = 0
        canCreateCustomCode = false
    }
    
    public func setLastReviewPromptDateToNow() {
        lastReviewPromptDate = .now
    }
}
