//
//  File.swift
//  
//
//  Created by Richard Witherspoon on 6/21/23.
//

import Foundation
import Models

public protocol PersistenceManaging {
    var canSaveFramedScreenshot: Bool  { get }
    var isSubscribed: Bool { get set }
    var autoSaveToFiles: Bool { get set }
    var autoSaveToPhotos: Bool  { get set }
    var autoDeleteScreenshots: Bool  { get set }
    var clearImagesOnAppBackground: Bool  { get set }
    var numberOfLaunches: Int  { get set }
    var numberOfActivations: Int  { get set }
    var deviceFrameCreations: Int  { get set }
    var imageSelectionType: ImageSelectionType  { get set }
    var imageQuality: ImageQuality  { get set }
    var lastReviewPromptDate: Date? { get set }
}
