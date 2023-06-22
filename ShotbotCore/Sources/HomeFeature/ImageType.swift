//
//  ImageType.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import Foundation


public enum ImageType: String, CaseIterable, Identifiable {
    case individual = "Individual"
    case combined = "Combined"
    
    public var id: String { rawValue }
}
