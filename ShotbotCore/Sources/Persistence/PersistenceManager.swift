//
//  PersistenceManager.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/23/23.
//

import SwiftUI
import Models

public final class PersistenceManager: ObservableObject, PersistenceManaging {
    public static let shared = PersistenceManager()
        
    private init(){}
    
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
    
    @AppStorage("isSubscribed")
    public var isSubscribed = false
    
    @AppStorage("autoSaveToFiles")
    public var autoSaveToFiles: Bool = false
    
    @AppStorage("autoSaveToPhotos")
    public var autoSaveToPhotos: Bool = false
    
    @AppStorage("autoDeleteScreenshots")
    public var autoDeleteScreenshots: Bool = false
    
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
}
