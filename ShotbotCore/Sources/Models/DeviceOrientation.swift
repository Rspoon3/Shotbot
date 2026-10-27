//
//  DeviceOrientation.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/25/26.
//

import Foundation

/// The orientation of a device frame.
public enum DeviceOrientation: String, Decodable, Sendable {
    case portrait = "Portrait"
    case landscape = "Landscape"
}
