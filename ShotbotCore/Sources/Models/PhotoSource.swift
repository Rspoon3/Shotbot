//
//  PhotoSource.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import SwiftUI
import PhotosUI

/// The source of where a `Screenshot` is coming from
public enum PhotoSource {
    case photoPicker([PhotosPickerItem])
    case photoAssetID(URL)
    case filePicker([URL])
    case dropItems([Data])
    case existingScreenshots([UIScreenshot])
    case controlCenter(Int)
}
