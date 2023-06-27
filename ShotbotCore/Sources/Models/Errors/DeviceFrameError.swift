//
//  SBError.swift
//  Shot Bot
//
//  Created by Richard Witherspoon on 4/20/23.
//

import Foundation

public enum SBError: LocalizedError {
    case noImage, noData, proSubscriptionRequired, unsupportedDevice, framing
    
    
    public var errorDescription: String? {
        switch self {
        case .noImage:
            return "No image"
        case .noData:
            return "No image data"
        case .proSubscriptionRequired:
            return "You've hit the free 30 framed screenshot limit. Please subscribe to Shotbot Pro to create unlimited screenshots."
        case .unsupportedDevice:
            return "Unsupported image. Please make sure you have a screenshot from a supported device."
        case .framing:
            return "An error occurred framing this screenshot."
        }
    }
}
