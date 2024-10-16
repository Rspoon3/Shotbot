//
//  RefreshLatestScreenshotIntent.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 7/19/24.
//

import AppIntents

struct RefreshLatestScreenshotIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh"
    static let isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
