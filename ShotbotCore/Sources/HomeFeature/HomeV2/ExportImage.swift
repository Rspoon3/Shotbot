//
//  ExportImage.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage
import CoreTransferable
import UniformTypeIdentifiers

/// A finished picture that is only turned into a PNG file when something asks for it, such as a drag, a share or a copy.
struct ExportImage: Transferable, @unchecked Sendable {
    /// The picture, at full size.
    let image: CIImage

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { item in
            SentTransferredFile(try item.writeFile())
        }
        .suggestedFileName("Framed Screenshot")
    }

    /// Writes the picture to a new PNG file in the temporary directory.
    func writeFile() throws -> URL {
        let url = URL.temporaryDirectory.appending(path: "Framed Screenshot \(UUID()).png")
        try LayerStore.shared.pngData(of: image).write(to: url)
        return url
    }
}
