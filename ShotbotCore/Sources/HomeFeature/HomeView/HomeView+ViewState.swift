
//
//  ViewState.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import Foundation
import Models

public extension HomeViewModel {
    enum ViewState: Equatable {
        public static func == (lhs: HomeViewModel.ViewState, rhs: HomeViewModel.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.combinedPlaceholder, .combinedPlaceholder):
                return true
            case (.individualPlaceholder, .individualPlaceholder):
                return true
            case (.combinedImages, .combinedImages):
                return true
            case (.individualImages, .combinedImages):
                return true
            default:
                return false
            }
        }
        
        case individualPlaceholder
        case individualImages([ShareableImage])
        case combinedImages(ShareableImage)
        case combinedPlaceholder
    }
}
