//
//  NotificationManager+Init.swift
//  Shotbot
//
//  Created by Ricky Witherspoon on 8/13/25.
//

import ReferralService

extension NotificationManager {
    public convenience override init() {
        self.init(referralService: .init())
    }
}
