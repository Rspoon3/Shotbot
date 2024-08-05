//
//  NotificationCenterProtocol.swift
//  ShotbotCore
//
//  Created by Richard Witherspoon on 8/4/24.
//

import Foundation

public protocol NotificationCenterProtocol {
    func publisher(
        for name: Notification.Name
    ) -> NotificationCenter.Publisher
}

extension NotificationCenter: NotificationCenterProtocol {
    public func publisher(for name: Notification.Name) -> Publisher {
        publisher(for: name, object: nil)
    }
}
