//
//  MockPhotoLibraryManager.swift
//  ShotbotTests
//
//  Created by Richard Witherspoon on 5/12/23.
//

import UIKit
import MediaManager

class MockPhotoLibraryManager: PhotoLibraryManaging {
    var didRequestPhotoLibraryAdditionAuthorizationError = false
    func requestPhotoLibraryAdditionAuthorization() async {
        didRequestPhotoLibraryAdditionAuthorizationError = true
    }
    
    var saveImageURLResult: Result<Void, Error>?
    func savePhoto(at url: URL) async throws {
        _ = try saveImageURLResult?.get()
    }
    
    var saveImageResult: Result<Void, Error>?
    func save(_ image: UIImage) async throws {
        _ = try saveImageResult?.get()
    }

    var deleteResult: Result<Void, Error>?
    func delete(_ itemIdentifiers: [String]) async throws {
        _ = try deleteResult?.get()
    }
}
