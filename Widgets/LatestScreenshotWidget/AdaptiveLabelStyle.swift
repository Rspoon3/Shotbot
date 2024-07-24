//
//  AdaptiveLabelStyle.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/22/24.
//

import SwiftUI

struct AdaptiveLabelStyle: LabelStyle {
    @Environment(\.widgetFamily) private var widgetFamily
    
    func makeBody(configuration: Configuration) -> some View {
        if widgetFamily == .systemSmall {
            Label(configuration)
                .labelStyle(.iconOnly)
        } else {
            Label(configuration)
        }
    }
}

extension LabelStyle where Self == AdaptiveLabelStyle {
    static var adaptive: AdaptiveLabelStyle {
      AdaptiveLabelStyle()
  }
}
