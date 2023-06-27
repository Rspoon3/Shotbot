//
//  File.swift
//  
//
//  Created by Richard Witherspoon on 6/21/23.
//

import UIKit

public protocol PhotoLibraryManaging {
    func requestPhotoLibraryAdditionAuthorization() async
    func savePhoto(at url: URL) async throws
    func save(_ image: UIImage) async throws
    func delete(_ itemIdentifiers: [String]) async throws
}
