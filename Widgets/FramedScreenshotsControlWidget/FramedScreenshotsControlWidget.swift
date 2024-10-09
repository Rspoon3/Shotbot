//
//  FramedScreenshotsControlWidget.swift
//  Shotbot
//
//  Created by Ricky on 10/1/24.
//
import AppIntents
import WidgetFeature
import WidgetKit
import SwiftUI
import Models

@available(iOS 18.0, *)
struct FramedScreenshotsControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: "FramedScreenshotsControlWidget",
            provider: ConfigurableProvider()
        ) { entity in
            ControlWidgetButton(action: SelectScreenshotTimeIntervalIntent(entity: entity)) {
                let title = entity == .latestScreenshot ? "Frame latest screenshot" : "Frame screenshots - \(entity.title)"
                Label(title, systemImage: "apps.iphone.badge.plus")
            }
        }
        .displayName("Frame Screenshots")
        .description("Frame your latest screenshot or screenshots from the past specified amount of minutes.")
        .promptsForUserConfiguration()
    }
}
