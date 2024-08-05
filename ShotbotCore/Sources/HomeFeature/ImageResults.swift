//
//  ImageResults.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/4/23.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import Models

public struct ImageResults {
    var originalScreenshots: [UIScreenshot] = []
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
        individual.removeAll()
        combined = nil
    }
}
