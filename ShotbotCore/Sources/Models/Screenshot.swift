//
//  Screenshot.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import SwiftUI

public typealias UIScreenshot = PlatformImage
public typealias UIFramedScreenshot = PlatformImage
public typealias Screenshot = Image
public typealias FramedScreenshot = Image

#if os(macOS)
import AppKit.NSImage
/// Alias for `NSImage`.
public typealias PlatformImage = NSImage
#else
import UIKit.UIImage
/// Alias for `UIImage`.
public typealias PlatformImage = UIImage
#endif


public extension Image {
    init(platformImage: PlatformImage) {
    #if os(macOS)
        self.init(nsImage: platformImage)
    #else
        self.init(uiImage: platformImage)
    #endif
    }
}


#if os(macOS)
public extension NSImage {
    convenience init?(systemName: String) {
        self.init(systemSymbolName: systemName, accessibilityDescription: nil)
    }
    
    func pngData() -> Data? {
        guard
            let tiffRepresentation = self.tiffRepresentation,
            let bitmapImage = NSBitmapImageRep(data: tiffRepresentation)
        else {
            return nil
        }
        
        return bitmapImage.representation(using: .png, properties: [:])
    }
}
#endif
