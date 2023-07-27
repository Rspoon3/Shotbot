//
//  ShareableImage.swift
//  ShotbotActionExtension
//
//  Created by Richard Witherspoon on 4/30/23.
//

import UIKit

public struct ShareableImage: Identifiable, Sendable {
    public let framedScreenshot: UIFramedScreenshot
    public let url: URL
    public let id = UUID()
    
    public init(framedScreenshot: UIFramedScreenshot, url: URL) {
        self.framedScreenshot = framedScreenshot
        self.url = url
    }
}
