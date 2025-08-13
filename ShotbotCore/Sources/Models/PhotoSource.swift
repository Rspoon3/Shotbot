//
//  PhotoSource.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import SwiftUI
import PhotosUI

/// The source of where a `Screenshot` is coming from
public enum PhotoSource: Sendable {
    case photoPicker([PhotosPickerItem])
    case photoAssetID(URL)
    case filePicker([URL])
    case dropItems([Data])
    
    // Used for changing quality mid frame
    case existingScreenshots([UIScreenshot])
    
    case controlCenter(Int)
    
    public var itemCount: Int? {
        switch self {
        case .photoPicker(let items): items.count
        case .filePicker(let urls): urls.count
        case .dropItems(let items): items.count
        case .existingScreenshots: 0
        case .controlCenter, .photoAssetID: nil
        }
    }
}
