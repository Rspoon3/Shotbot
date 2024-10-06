//
//  ImageManaging.swift
//  
//
//  Created by Richard Witherspoon on 7/22/24.
//

import UIKit

public protocol ImageManaging {
    func latestScreenshot(from url: URL) async throws -> UIImage
    func latestScreenshot(targetSize: CGSize) async throws -> (image: UIImage, assetID: String)
    func multipleScreenshots(within duration: Int) async throws -> [UIImage]
}
