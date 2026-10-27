//
//  FramedVideo.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import Foundation

/// A screen recording that has been put inside a device frame.
public struct FramedVideo: Identifiable, Sendable {
    public let id = UUID()
    /// The framed MP4 in the temporary directory.
    public let url: URL
    /// The unframed recording, kept so the video can be framed again in another color or view.
    public let sourceURL: URL
    /// The device the video was framed with.
    public let device: DeviceInfo

    public init(url: URL, sourceURL: URL, device: DeviceInfo) {
        self.url = url
        self.sourceURL = sourceURL
        self.device = device
    }
}
