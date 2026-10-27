//
//  BackgroundImages.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreGraphics
import Foundation
import ImageIO

/// Pictures bundled with the app that can be used behind framed devices.
public enum BackgroundImages {
    /// A black and white album cover, a busy photo for seeing how well backgrounds hold up behind a device.
    public static let reputation: CGImage? = image(named: "Reputation", withExtension: "jpg")

    private static func image(named name: String, withExtension fileExtension: String) -> CGImage? {
        guard
            let url = Bundle.module.url(forResource: name, withExtension: fileExtension),
            let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
