//
//  DeviceRender.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage

/// The finished layers of one framed screenshot, ready to be placed in a scene.
///
/// Both images live on the GPU and are kept at full resolution, so building a scene from them is only a matter of
/// moving them around.
struct DeviceRender: @unchecked Sendable {
    /// The device with the screenshot in it, on a transparent background, starting at the origin.
    let device: CIImage
    /// A soft shadow for the device. It reaches past the device's edges, so it can start below and left of the origin.
    /// `nil` when the device draws its own, like the partially open view.
    let shadow: CIImage?

    /// The size of the device.
    var size: CGSize { device.extent.size }
}
