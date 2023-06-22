//
//  ImageResults.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/4/23.
//

import UIKit
import Models

struct ImageResults {
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
