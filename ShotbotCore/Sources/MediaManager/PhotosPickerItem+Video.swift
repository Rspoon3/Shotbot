//
//  PhotosPickerItem+Video.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// A video file copied out of the photo library into the temporary directory.
private struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            // The received file is deleted when this closure returns, so keep a copy.
            let copy = URL.temporaryDirectory.appending(path: "Source Video \(UUID()).\(received.file.pathExtension)")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return PickedVideo(url: copy)
        }
    }
}

public extension PhotosPickerItem {
    /// Whether the item is a video rather than an image.
    var isVideo: Bool {
        supportedContentTypes.contains { $0.conforms(to: .movie) }
    }

    /// Copies the video to the temporary directory.
    /// - Returns: The copy's URL, or `nil` if the item couldn't be loaded.
    func loadVideoURL() async throws -> URL? {
        try await loadTransferable(type: PickedVideo.self)?.url
    }
}
