//
//  RefreshLatestScreenshotIntent.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 7/19/24.
//

import AppIntents

struct RefreshLatestScreenshotIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
