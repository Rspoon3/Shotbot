//
//  MockPersistenceManager.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 5/12/23.
//

import Foundation
import Persistence
import Models

class MockPersistenceManager: PersistenceManaging {
    var canSaveFramedScreenshot: Bool = false
    var isSubscribed: Bool = false
    var numberOfLaunches: Int = 0
    var numberOfActivations: Int = 0
    var deviceFrameCreations: Int = 0
    var autoSaveToFiles: Bool = false
    var autoSaveToPhotos: Bool = false
    var autoDeleteScreenshots: Bool = false
    var clearImagesOnAppBackground: Bool = false
    var imageSelectionType: ImageSelectionType = .all
    var imageQuality: ImageQuality = .original

    func reset() {
        canSaveFramedScreenshot = false
        isSubscribed = false
        autoSaveToFiles = false
        autoSaveToPhotos = false
        autoDeleteScreenshots = false
        clearImagesOnAppBackground = false
        numberOfLaunches = 0
        numberOfActivations = 0
        deviceFrameCreations = 0
        imageSelectionType = .all
        imageQuality = .original
    }
}
