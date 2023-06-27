//
//  PhotoSource.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import Foundation

/// The source of where a `Screenshot` is coming from
public enum PhotoSource {
    case photoPicker
    case dropItems([Data])
    case existingScreenshots([UIScreenshot])
}
