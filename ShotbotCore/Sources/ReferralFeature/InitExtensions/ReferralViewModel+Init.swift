//
//  ReferralViewModel+Init.swift
//  Shotbot
//
//  Created by Ricky Witherspoon on 8/13/25.
//

import ReferralService

extension ReferralViewModel {
    public convenience init() {
        self.init(
            shareText: "📸 The fastest way to create and share beautiful screenshots!",
            referralService: .init()
        )
    }
}
