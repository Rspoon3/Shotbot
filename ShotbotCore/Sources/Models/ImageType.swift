//
//  ImageType.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import Foundation

/// An object that determines if an image is an individual image or a combined image
/// comprised of individual images stitched together.
public enum ImageType: String, CaseIterable, Identifiable {
    case individual = "Individual"
    case combined = "Combined"
    
    public var id: String { rawValue }
}
