//
//  ProcessedScreenshot.swift
//  ShotbotCore
//
//  Created by Claude on 6/28/25.
//

import UIKit
import Models
import Foundation

public struct ProcessedScreenshot: Identifiable {
    public let id = UUID()
    public let image: UIImage
    public let deviceInfo: DeviceInfo
    
    public init(image: UIImage, deviceInfo: DeviceInfo) {
        self.image = image
        self.deviceInfo = deviceInfo
    }
}

extension ProcessedScreenshot: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ProcessedScreenshot, rhs: ProcessedScreenshot) -> Bool {
        lhs.id == rhs.id
    }
}
