//
//  ConfigurableProvider.swift
//  Shotbot
//
//  Created by Ricky on 10/5/24.
//

#if canImport(WidgetKit)
import WidgetKit

@available(iOS 18.0, *)
extension FramedScreenshotsControlWidget {
    struct ConfigurableProvider: AppIntentControlValueProvider {
        func previewValue(configuration: SelectScreenshotTimeIntervalIntent) -> ScreenshotTimeIntervalEntity {
            configuration.entity ?? .latestScreenshot
        }
        
        func currentValue(configuration: SelectScreenshotTimeIntervalIntent) async throws -> ScreenshotTimeIntervalEntity {
            configuration.entity ?? .latestScreenshot
        }
    }
}
#endif
