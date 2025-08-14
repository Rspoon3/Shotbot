//
//  ReferralChecker+Init.swift
//  Shotbot
//
//  Created by Ricky Witherspoon on 8/13/25.
//

import ReferralService
import Persistence

extension ReferralChecker {
    public init() {
        self.init(
            referralService: .init(),
            referralDataStorage: PersistenceManager.shared
        )
    }
}
