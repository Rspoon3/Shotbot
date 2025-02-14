//
//  CGSize+Extension.swift
//  ShotbotTests
//
//  Created by Richard Witherspoon on 4/20/23.
//

import Foundation
import CoreGraphics

extension CGSize: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
