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
    func copyToiCloudFiles(from source: URL, using path: String) throws {
        _ = try copyResult?.get()
    }
}
