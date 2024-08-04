//
//  SKStoreReviewControlling.swift
//  ShotbotCore
//
//  Created by Richard Witherspoon on 7/24/24.
//

import Foundation
import StoreKit

public protocol SKStoreReviewControlling {
    @MainActor static func requestReview(in windowScene: UIWindowScene)
}

extension SKStoreReviewController: SKStoreReviewControlling { }
