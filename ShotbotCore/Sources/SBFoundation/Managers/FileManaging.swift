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
    func write(_ data: Data, to filePath: URL, options: Data.WritingOptions) throws
    func removeItem(at URL: URL) throws
    func contentsOfDirectory(at url: URL) throws -> [URL]
}

extension FileManager: FileManaging {
    public func contentsOfDirectory(at url: URL) throws -> [URL] {
        try contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }
    
    public func copyToiCloudFiles(from source: URL) throws {
        guard let driveURL = url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            throw SBError.missingiCloudDirectory
        }
        
        let url = driveURL.appendingPathComponent(source.lastPathComponent)
        
        
        try copyItem(at: source, to: url)
    }
    
    public func write(_ data: Data, to filePath: URL, options: Data.WritingOptions) throws {
        try data.write(to: filePath, options: options)
    }
}
