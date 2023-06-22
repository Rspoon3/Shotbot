//
//  FileManaging.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 5/12/23.
//

import Foundation

public protocol FileManaging {
    func copyItem(at srcURL: URL, to dstURL: URL) throws
}

extension FileManager: FileManaging {}
