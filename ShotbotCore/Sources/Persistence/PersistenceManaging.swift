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

    /// When true, always prompt for device selection on ambiguous matches instead of using cached preferences.
    var alwaysAskDeviceFrame: Bool { get set }

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

    // MARK: - Device Color Preferences

    /// Returns the frame color the user last picked for a device model, such as "Cosmic Orange" for "iPhone 17 Pro".
    func preferredColor(for deviceName: String) -> String?

    /// Stores the frame color the user picked for a device model, so it is the default the next time that device is framed.
    func setPreferredColor(_ color: String, for deviceName: String)

    // MARK: - Device View Preferences

    /// Returns the frame view the user last picked for a screen, such as "Open" for the iPhone Duo's outer screen.
    /// - Parameter key: `DeviceInfo.viewPreferenceKey`.
    func preferredView(forKey key: String) -> String?

    /// Stores the frame view the user picked for a screen, so it is the default the next time that screen is framed.
    /// - Parameters:
    ///   - view: The view's name.
    ///   - key: `DeviceInfo.viewPreferenceKey`.
    func setPreferredView(_ view: String, forKey key: String)
}

public extension PersistenceManaging {
    /// Returns the device with the color and view the user last picked for it. A choice the device doesn't offer is ignored.
    /// - Parameter device: A device, usually straight from `DeviceInfo.match(for:)`.
    func applyingPreferredStyle(to device: DeviceInfo) -> DeviceInfo {
        var styled = device

        if let color = preferredColor(for: device.name) {
            styled = styled.withColor(color)
        }

        if let view = preferredView(forKey: device.viewPreferenceKey) {
            styled = styled.withView(view)
        }

        return styled
    }
}
