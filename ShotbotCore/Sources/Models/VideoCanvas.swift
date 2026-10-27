//
//  VideoCanvas.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage

/// Where a framed device goes on the finished video: a canvas of any size, with a background around the device.
public struct VideoCanvas: @unchecked Sendable {
    /// The size of the finished video.
    public let size: CGSize
    /// Puts one framed video frame on the canvas.
    ///
    /// Called for every frame, so it should only describe the picture, not draw it. The frame it is given has a
    /// transparent background and starts at the origin. A partially open device already has its shadow in it.
    public let place: @Sendable (_ device: CIImage) -> CIImage

    public init(size: CGSize, place: @escaping @Sendable (_ device: CIImage) -> CIImage) {
        self.size = size
        self.place = place
    }
}
