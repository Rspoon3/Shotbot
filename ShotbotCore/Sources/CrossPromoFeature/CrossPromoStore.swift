//
//  CrossPromoStore.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 1/17/25.
//

import Foundation

public final class CrossPromoStore {
    private let userDefaults: UserDefaults
    private let bannerCountKey = "photoRankerBannerCount"
    private let lastShownKey = "photoRankerBannerLastShown"

    private var bannerCount: Int {
        get { userDefaults.integer(forKey: bannerCountKey) }
        set { userDefaults.set(newValue, forKey: bannerCountKey) }
    }
    
    private var lastShownDate: Date? {
        get { userDefaults.object(forKey: lastShownKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastShownKey) }
    }

    // MARK: - Initializer
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Public

    public func shouldShowBanner() -> Bool {
        // Check if we've shown the banner 3 times already
        guard bannerCount < 3 else { return false }

        // If never shown before, show it
        guard let lastShownDate else { return true }

        // Check if 7 days have passed since last shown
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        return lastShownDate < oneWeekAgo
    }

    public func recordBannerShown() {
        bannerCount += 1
        lastShownDate = .now
    }
}
