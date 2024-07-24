//
//  WidgetsBundle.swift
//  Widgets
//
//  Created by Richard Witherspoon on 7/19/24.
//

import WidgetKit
import SwiftUI

@main
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        LatestScreenshotWidget()
        MultipleScreenshotsWidget()
    }
}
