//
//  MergeMethod.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import Foundation

public enum MergeMethod: String, Decodable {
    case singleOverlay
    case singleOverlayV2
    case doubleOverlay
    case islandOverlay
}
