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
        guard let driveURL = url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            throw FileError.missingiCloudDirectory
        }
        
        let url = driveURL.appendingPathComponent(path)
        
        try copyItem(at: source, to: url)
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
