//
//  FileManaging.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 5/12/23.
//

import Foundation
import Models

public protocol FileManaging {
    func copyToiCloudFiles(from source: URL) throws
}

extension FileManager: FileManaging {
    public func copyToiCloudFiles(from source: URL) throws {
        guard let driveURL = url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            throw SBError.missingiCloudDirectory
        }
        
        let url = driveURL.appendingPathComponent(source.lastPathComponent)
        
        try copyItem(at: source, to: url)
    }
}
