//
//  ReferralService+Init.swift
//  ReferralService
//
//  Created by Ricky Witherspoon on 6/30/25.
//

import Foundation
import ReferralService

extension ReferralService {
    public init(userDefaults: UserDefaults = .standard) {
        let useProductionCloudKit = userDefaults.bool(forKey: "useProductionCloudKit")
        let useProductionHMAC = userDefaults.bool(forKey: "useProductionHMACConfig")
        
        self.init(
            useProductionCloudKit: useProductionCloudKit,
            useProductionHMAC: useProductionHMAC,
            appID: 6450552843,
            cache: .shared
        )
    }
}
