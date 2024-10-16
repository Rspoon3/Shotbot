//
//  SelectScreenshotTimeIntervalIntent.swift
//  Shotbot
//
//  Created by Ricky on 10/5/24.
//

import AppIntents
import Models

@available(iOS 18.0, *)
struct SelectScreenshotTimeIntervalIntent: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Select Time Interval"
    static let description: IntentDescription = "Used to frame your latest screenshot or screenshots from the past specified amount of minutes."
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Time Interval", optionsProvider: OptionsProvider())
    var entity: ScreenshotTimeIntervalEntity?
    
    struct OptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [ScreenshotTimeIntervalEntity] {
            ScreenshotTimeIntervalEntity.allCases
        }
    }
    
    init() { }
    init(entity: ScreenshotTimeIntervalEntity) {
        self.entity = entity
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        AppIntentManager.shared.selectTimeIntervalIntentID = entity?.rawValue
        return .result()
    }
}
