//
//  PhotosPickerItem+Extension.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import SwiftUI
import PhotosUI
import CollectionConcurrencyKit
import Models

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public extension Array where Element == PhotosPickerItem {
    func loadUImages() async throws -> [PlatformImage] {
        try await asyncMap {
            guard
                let data = try await $0.loadTransferable(type: Data.self),
                let screenshot = PlatformImage(data: data)
            else {
                throw SBError.unsupportedImage
            }
            
            return screenshot
        }
    }
}
