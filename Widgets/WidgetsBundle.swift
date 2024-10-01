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
        if #available(iOSApplicationExtension 18.0, *) {
            return allWidgetsIncludingiOS18
        } else {
            return noniOS18OnlyWidgets
        }
    }
    
    @WidgetBundleBuilder
    var noniOS18OnlyWidgets: some Widget {
        LatestScreenshotWidget()
        MultipleScreenshotsWidget()
    }
    
    @available(iOSApplicationExtension 18.0, *)
    @WidgetBundleBuilder
    var allWidgetsIncludingiOS18: some Widget {
        noniOS18OnlyWidgets
        MultipleScreenshotsControlWidget()
    }
}
