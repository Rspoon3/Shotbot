//
//  ExportImage.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreTransferable
import UniformTypeIdentifiers

/// A finished picture that is only turned into a PNG file when something asks for it, such as a drag or a share. If the
/// file was already made ahead of time, it is used as it is.
struct ExportImage: Transferable, Sendable {
    let export: PNGExport

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { item in
            SentTransferredFile(try await item.export.file(), allowAccessingOriginalFile: false)
        }
        .suggestedFileName("Framed Screenshot")
    }
}
