//
//  CGSize+Swapped.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/25/26.
//

import CoreGraphics

extension CGSize {
    /// The size with its width and height swapped, such as a portrait size turned into landscape.
    var swapped: CGSize {
        CGSize(width: height, height: width)
    }
}
