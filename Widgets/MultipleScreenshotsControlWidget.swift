//
//  MultipleScreenshotsControlWidget.swift
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
struct MultipleScreenshotsControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: "MultipleScreenshotsControlWidget",
            provider: ConfigurableProvider()
        ) { option in
            ControlWidgetButton(action: SelectDurationIntent(durationOption: option)) {
                Label(
                    "Frame screenshots - \(option.title)",
                    systemImage: "apps.iphone.badge.plus"
                )
            }
        }
        .displayName("Frame Screenshots")
        .description("Frame your latest screenshot or screenshots from the past specified amount of minutes.")
        .promptsForUserConfiguration()
    }
}

@available(iOS 18.0, *)
struct ConfigurableProvider: AppIntentControlValueProvider {
    func previewValue(configuration: SelectDurationIntent) -> DurationWidgetAppEntity {
        configuration.durationOption ?? .latestScreenshot
    }
    
    func currentValue(configuration: SelectDurationIntent) async throws -> DurationWidgetAppEntity {
        configuration.durationOption ?? .latestScreenshot
    }
}

public enum DurationWidgetAppEntity: Int, CaseIterable, AppEntity {
    case latestScreenshot = 0
    case oneMinute = 1
    case fifteenMinutes = 2
    case thirtyMinutes = 3
    case sixtyMinutes = 4
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Duration"
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
    
    public var title: String {
        switch self {
        case .latestScreenshot:
            return "Latest screenshot"
        case .oneMinute:
            return "1 minute"
        case .fifteenMinutes:
            return "5 minutes"
        case .thirtyMinutes:
            return "15 minutes"
        case .sixtyMinutes:
            return "60 minutes"
        }
    }
}

@available(iOS 18.0, *)
struct SelectDurationIntent: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Select Duration"
    static let description: IntentDescription = "Used to frame your latest screenshot or screenshots from the past specified amount of minutes."
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Duration", optionsProvider: OptionsProvider())
    var durationOption: DurationWidgetAppEntity?
    
    struct OptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [DurationWidgetAppEntity] {
            DurationWidgetAppEntity.allCases
        }
    }
    
    init() { }
    init(durationOption: DurationWidgetAppEntity) {
        self.durationOption = durationOption
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        AppIntentManager.shared.selectDurationIntentID = durationOption?.rawValue
        return .result()
    }
}
