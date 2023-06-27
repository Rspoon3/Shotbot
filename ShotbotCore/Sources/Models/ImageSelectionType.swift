//
//  ImageSelectionType.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/24/23.
//

import Foundation
import PhotosUI

public enum ImageSelectionType: Int, CaseIterable, Identifiable {
    case screenshots, all
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .screenshots:
            return "Screenshots"
        case .all:
            return "All Images"
        }
    }
    
    public var filter: PHPickerFilter {
        switch self {
        case .screenshots:
            return .screenshots
        case .all:
            return .images
        }
    }
}
