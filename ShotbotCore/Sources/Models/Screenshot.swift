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
