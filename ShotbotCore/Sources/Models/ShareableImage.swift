//
//  ShareableImage.swift
//  ShotbotActionExtension
//
//  Created by Richard Witherspoon on 4/30/23.
//

import UIKit

public struct ShareableImage: Identifiable, Sendable {
    public let framedScreenshot: UIFramedScreenshot
    public var framedBackgroundScreenshot: UIImage
    public let url: URL
    public let id = UUID()
    
    public init(
        framedScreenshot: UIFramedScreenshot,
        framedBackgroundScreenshot: UIImage = UIImage(),
        url: URL
    ) {
        self.framedScreenshot = framedScreenshot
        self.framedBackgroundScreenshot = framedBackgroundScreenshot
        self.url = url
    }
}
