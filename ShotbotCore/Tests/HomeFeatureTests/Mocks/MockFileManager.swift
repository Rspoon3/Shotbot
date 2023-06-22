//
//  MockFileManager.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 5/12/23.
//

import Foundation
import HomeFeature

class MockFileManager: FileManaging {
    var copyResult: Result<Void, Error>?
    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        _ = try copyResult?.get()
    }
}
