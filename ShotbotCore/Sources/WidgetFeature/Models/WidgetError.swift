//
//  WidgetError.swift
//
//
//  Created by Richard Witherspoon on 7/24/24.
//

import Foundation

public struct WidgetError: LocalizedError {
    public let errorDescription: String?
    public let recoverySuggestion: String?
    
    public static func noImages(for durationOption: DurationWidgetOption) -> Self {
        Self(
            errorDescription: "No images",
            recoverySuggestion: "No screenshots found in the last \(durationOption.errorTitle)."
        )
    }
}
