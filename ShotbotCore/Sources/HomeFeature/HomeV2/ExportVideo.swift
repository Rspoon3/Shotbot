//
//  ExportVideo.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreTransferable
import Models
import UniformTypeIdentifiers

/// A framed video that is only rendered to a file when something asks for it, such as a share or a drag.
struct ExportVideo: Transferable, Sendable {
    let video: PreparedVideo

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .mpeg4Movie) { item in
            SentTransferredFile(try await item.writeFile())
        }
        .suggestedFileName("Framed Video")
    }

    /// Renders the video to a new MP4 file in the temporary directory.
    func writeFile() async throws -> URL {
        let url = URL.temporaryDirectory.appending(path: "Framed Video \(UUID()).mp4")
        try await VideoFramer().export(video, to: url)
        return url
    }
}
