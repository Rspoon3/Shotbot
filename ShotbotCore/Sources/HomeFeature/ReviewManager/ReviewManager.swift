//
//  ReviewManager.swift
//  ShotbotCore
//
//  Created by Richard Witherspoon on 7/24/24.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import OSLog
import Persistence
import StoreKit

public protocol ReviewManaging {
    @MainActor func askForAReview()
}

/// An object that is responsible for prompting the user for a review if the acceptance criteria
/// is met.
public final class ReviewManager: ReviewManaging {
    private var persistenceManager: any PersistenceManaging
    #if !os(macOS)
    private var skStoreReviewController: any SKStoreReviewControlling.Type
    #endif
    private let logger = Logger(category: ReviewManager.self)
    
    // MARK: - Initializer
    
#if os(macOS)
    public init(
        persistenceManager: any PersistenceManaging = PersistenceManager.shared
    ){
        self.persistenceManager = persistenceManager
    }
    #else
    public init(
        persistenceManager: any PersistenceManaging = PersistenceManager.shared,
        skStoreReviewController: any SKStoreReviewControlling.Type = SKStoreReviewController.self
    ){
        self.persistenceManager = persistenceManager
        self.skStoreReviewController = skStoreReviewController
    }
    #endif

    // MARK: - Public
    
    /// Asks the user for a review if the acceptance criteria is met.
    @MainActor public func askForAReview() {
        #if !os(macOS)
        let deviceFrameCreations = persistenceManager.deviceFrameCreations
        let numberOfActivations = persistenceManager.numberOfActivations
        
        guard deviceFrameCreations > 3 && numberOfActivations > 3 else {
            logger.debug("Review prompt criteria not met. DeviceFrameCreations: \(deviceFrameCreations, privacy: .public), numberOfActivations: \(numberOfActivations, privacy: .public).")
            return
        }
        
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            logger.fault("Could not find UIWindowScene to ask for review")
            return
        }
        
        if let date = persistenceManager.lastReviewPromptDate {
            guard date >= Date.now.adding(3, .day) else {
                logger.debug("Last review prompt date to recent: \(date, privacy: .public).")
                return
            }
        }
        
        skStoreReviewController.requestReview(in: scene)
        persistenceManager.lastReviewPromptDate = .now
        logger.log("Prompting the user for a review")
        #endif
    }
}
