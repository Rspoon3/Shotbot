//
//  ImageResults.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/4/23.
//

import UIKit
import Models

public struct ImageResults {
    var originalScreenshots: [UIScreenshot] = []
    /// The device each original screenshot was framed with, in the same order, so re-framing never asks again.
    var devices: [DeviceInfo] = []
    var individual: [ShareableImage] = []
    var combined: ShareableImage?
    
    var hasImages: Bool {
        !individual.isEmpty
    }
    
    var hasMultipleImages: Bool {
        individual.count > 1
    }
    
    mutating func removeAll() {
        originalScreenshots.removeAll()
        devices.removeAll()
        individual.removeAll()
        combined = nil
    }
    
    mutating func reverseImages() {
        originalScreenshots.reverse()
        devices.reverse()
        individual.reverse()
    }
}
