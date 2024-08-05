//
//  SBError.swift
//  Shot Bot
//
//  Created by Richard Witherspoon on 4/20/23.
//

import Foundation

public struct SBError: LocalizedError, Equatable {
    public let errorDescription: String?
    public let recoverySuggestion: String?
    
    public static let lowMemoryWarning = Self(
        errorDescription: "Low Memory",
        recoverySuggestion: "The device is running low on memory. Please either reduce the amount of images being framed at once or decrease the image quality."
    )
    public static let unsupportedImage = Self(
        errorDescription: "Unsupported Image",
        recoverySuggestion: "Please make sure you the image selected is a supported screenshot"
    )
    
    public static let noImageData = Self(
        errorDescription: "No image data",
        recoverySuggestion: "The data for this image could not be fetched"
    )
    
    public static let noData = Self(
        errorDescription: "No data",
        recoverySuggestion: "The data could not be generated"
    )
    
    public static let proSubscriptionRequired = Self(
        errorDescription: "Shotbot Pro Required",
        recoverySuggestion: "You've hit the free 30 framed screenshot limit. Please subscribe to Shotbot Pro to create unlimited screenshots"
    )
    
    public static let unsupportedDevice = Self(
        errorDescription: "Unsupported Image",
        recoverySuggestion: "Please make sure you have a screenshot from a supported device"
    )
    
    public static let framing = Self(
        errorDescription: "Framing Error",
        recoverySuggestion: "An error occurred framing this screenshot"
    )
    
    public static let missingiCloudDirectory = Self(
        errorDescription: "Directory Not Found",
        recoverySuggestion: "The iCloud directory in the 'Files' app could not be found"
    )
    
    public static let insufficientPhotoAuthorization = Self(
        errorDescription: "Insufficient Photos Authorization",
        recoverySuggestion: "Update the photos authorization to save to your photo library."
    )
    
    public static let noAnnualPackage = Self(
        errorDescription: "Purchase Error",
        recoverySuggestion: "This purchase item could not be found"
    )
    
    public static let noSelf = Self(
        errorDescription: "Memory Issue",
        recoverySuggestion: "A memory issue occurred"
    )
}
