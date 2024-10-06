//
//  ImageManaging.swift
//  
//
//  Created by Richard Witherspoon on 7/22/24.
//

import UIKit

public protocol ImageManaging {
    func latestScreenshot(using option: ImageManager.ScreenshotFetchOption) async throws -> (image: UIImage, assetID: String?)
    func multipleScreenshots(for option: DurationWidgetOption) async throws -> [UIImage]
}
