//
//  PhotosPickerItem+Extension.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import SwiftUI
import PhotosUI
import CollectionConcurrencyKit
import UIKit
import Models

public extension Array where Element == PhotosPickerItem {
    func loadUImages() async throws -> [UIImage] {
        try await asyncMap {
            guard
                let data = try await $0.loadTransferable(type: Data.self),
                let screenshot = UIImage(data: data)
            else {
                throw SBError.noImage
            }
            
            return screenshot
        }
    }
}
