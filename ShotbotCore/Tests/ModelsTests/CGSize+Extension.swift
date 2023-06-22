//
//  CGSize+Extension.swift
//  Shot BotTests
//
//  Created by Richard Witherspoon on 4/20/23.
//

import Foundation
import CoreGraphics

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
