//
//  ImageQuality.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 5/20/23.
//

import Foundation
import AppIntents

public enum ImageQuality: String, CaseIterable, Identifiable, Sendable {
    
    case original = "Original"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case poor = "Poor"
    
    public var id: String { rawValue }
    
    public var value: Double {
        switch self {
        case .original:
            return 1.0
        case .high:
            return 0.8
        case .medium:
            return 0.6
        case .low:
            return 0.4
        case .poor:
            return 0.2
        }
    }
}


//
//
//extension ImageQuality: AppEnum {
//    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
//        "Image Quality"
//    }
//    
//    public static var typeDisplayName: LocalizedStringResource = "Image Quality"
//    
//    public static var caseDisplayRepresentations: [ImageQuality: DisplayRepresentation] = [
//        .original: "Original",
//        .high: "High",
//        .medium: "Medium",
//        .low: "Low",
//        .poor: "Poor"
//    ]
//}



//public struct IceCreamAppIntents: AppIntentsPackage { }


//
//import SwiftUI
//import AppIntents
//import CollectionConcurrencyKit
//import OSLog
//
//struct CreateFramedScreenshotsIntent: AppIntent {
//    static let intentClassName = "CreateFramedScreenshotsIntent"
//    static var title: LocalizedStringResource = "Create Framed Screenshots"
//    static var description = IntentDescription("Creates framed screenshots with a device frame using the images passed in.")
//    private let logger = Logger(category: CreateFramedScreenshotsIntent.self)
//    
//    @Parameter(
//        title: "Images",
//        description: "The plain screenshots passed in that will be framed.",
//        supportedTypeIdentifiers: ["public.image"],
//        inputConnectionBehavior: .connectToPreviousIntentResult
//    )
//    var images: [IntentFile]
//    
//    @Parameter(
//        title: "Save to files",
//        description: "Will automatically save each image to the files app."
//    )
//    var saveToFiles: Bool
//    
//    @Parameter(
//        title: "Save to photos",
//        description: "Will automatically save each image to your photo library."
//    )
//    var saveToPhotos: Bool
//    
//    @Parameter(
//        title: "Image Quality",
//        description: "The quality of the screenshot.",
//        default: .original
//    )
//    var imageQuality: ImageQuality
//    
//    static var parameterSummary: some ParameterSummary {
//        Summary("Create screenshots from \(\.$images)") {
//            \.$saveToFiles
//            \.$saveToPhotos
//            \.$imageQuality
//        }
//    }
//    
//    
//    // MARK: - Functions
//    
//    func perform() async throws -> some IntentResult {
//        return .result()
//    }
//}
