//
//  UIPasteboard+Extension.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 11/17/24.
//

import UIKit

public extension UIPasteboard {
    /// Copies multiple images to the pasteboard using PNG data
    /// - Parameter images: The array of UIImages to copy
    func set(_ images: [UIImage]) {
        let pasteboardItems: [[String: Any]] = images.compactMap { image in
            guard let pngData = image.pngData() else { return nil }
            return ["public.png": pngData]
        }
        setItems(pasteboardItems)
    }
}
