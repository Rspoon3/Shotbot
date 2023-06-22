//
//  FileManaging.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 5/12/23.
//

import Foundation

public protocol FileManaging {
    func copyToiCloudFiles(from source: URL, using path: String) throws
}

extension FileManager: FileManaging {
    public func copyToiCloudFiles(from source: URL, using path: String) throws {
        guard let driveURL = url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents/\(path)") else {
            throw FileError.missingiCloudDirectory
        }
        
        try copyItem(at: source, to: driveURL)
    }
}

public enum FileError: LocalizedError {
    case missingiCloudDirectory
    
    public var errorDescription: String? {
        switch self {
        case .missingiCloudDirectory:
            return "The files directory could not be found."
        }
    }
}
