//
//  File.swift
//  
//
//  Created by Richard Witherspoon on 6/21/23.
//

import Foundation
import Models

public protocol PersistenceManaging: Sendable {
    var isSubscribed: Bool { get set }
    var referralBannerCount: Int { get set }
    var autoCopyOption: AutoActionOption  { get set }
    var autoSaveFilesOption: AutoActionOption { get set }
    var autoSavePhotosOption: AutoActionOption  { get set }
    var autoDeleteScreenshots: Bool  { get set }
    var defaultHomeTab: ImageType { get set }
    var defaultHomeView: HomeViewType { get set }
    var clearImagesOnAppBackground: Bool  { get set }
    var numberOfLaunches: Int  { get set }
    var numberOfActivations: Int  { get set }
    var deviceFrameCreations: Int  { get set }
    var imageSelectionType: ImageSelectionType  { get set }
    var imageQuality: ImageQuality  { get set }
    var lastReviewPromptDate: Date? { get set }
    var creditBalance: Int { get set }
    var canEnterReferralCode: Bool { get set }
    func setLastReviewPromptDateToNow()

    // MARK: - Device Frame Preferences

    /// Returns the user's preferred device frame name for the given screenshot size, if cached.
    func preferredDeviceFrame(for size: CGSize) -> String?

    /// Stores the user's preferred device frame name for the given screenshot size.
    func setPreferredDeviceFrame(_ frameName: String, for size: CGSize)

    /// Removes all cached device frame preferences.
    func clearDeviceFramePreferences()

    /// Removes the cached device frame preference for the given screenshot size.
    func removeDeviceFramePreference(for size: CGSize)

    /// Whether any device frame preferences have been cached.
    var hasDeviceFramePreferences: Bool { get }

    /// All cached device frame preferences keyed by size string (e.g. "1170x2532") mapped to the device frame name.
    var deviceFramePreferences: [String: String] { get }
}
