//
//  PreparedVideo.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import AVFoundation
import CoreImage

/// A recording and the framing to apply to it, ready to show or export.
///
/// Nothing is rendered when this is made. `renderFrame` describes the framing of one frame, so a player can draw it
/// live frame by frame, and a file is only written by `VideoFramer.export(_:to:)`, which uses the same description.
public struct PreparedVideo: Identifiable, @unchecked Sendable {
    public let id = UUID()
    /// The unframed recording.
    public let asset: AVURLAsset
    /// How each frame is framed for export, in the recording's own color space so HDR stays HDR.
    public let composition: AVVideoComposition
    /// The size of the finished video.
    public let renderSize: CGSize
    /// The turn the recording is stored with, which players that read raw frames have to undo.
    let preferredTransform: CGAffineTransform
    private let framing: @Sendable (CIImage) -> CIImage

    /// Frames one upright video frame.
    ///
    /// - Parameter frame: A frame of the recording, right side up.
    /// - Returns: The frame inside the device, on the canvas, starting at the origin.
    public func renderFrame(_ frame: CIImage) -> CIImage {
        framing(frame)
    }

    /// Turns a raw frame, as stored in the file, right side up and moves it to the origin.
    public func upright(_ rawFrame: CIImage) -> CIImage {
        let transform = preferredTransform
        let orientation: CGImagePropertyOrientation

        if transform.b == 1, transform.c == -1 {
            orientation = .right
        } else if transform.b == -1, transform.c == 1 {
            orientation = .left
        } else if transform.a == -1, transform.d == -1 {
            orientation = .down
        } else {
            orientation = .up
        }

        let turned = rawFrame.oriented(orientation)
        return turned.transformed(by: CGAffineTransform(translationX: -turned.extent.minX, y: -turned.extent.minY))
    }

    init(
        asset: AVURLAsset,
        composition: AVVideoComposition,
        renderSize: CGSize,
        preferredTransform: CGAffineTransform,
        framing: @escaping @Sendable (CIImage) -> CIImage
    ) {
        self.asset = asset
        self.composition = composition
        self.renderSize = renderSize
        self.preferredTransform = preferredTransform
        self.framing = framing
    }
}
