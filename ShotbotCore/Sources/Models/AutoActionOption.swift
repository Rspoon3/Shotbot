//
//  AutoActionOption.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 11/17/24.
//

import Foundation

/// An option that determines what should be automatically acted upon (saved, copied, etc.)
public enum AutoActionOption: String, CaseIterable, Identifiable, Sendable {
    case none = "None"
    case individual = "Individual Only"
    case combined = "Combined Only"
    case all = "All"

    public var id: String { rawValue }
}
