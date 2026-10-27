//
//  PNGExport.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage

/// Turns one finished picture into a PNG file, at most once.
///
/// Encoding a large PNG takes a noticeable moment, so it runs away from the main thread, can be started before anyone
/// asks for the file, and is shared: a share, a drag and a copy of the same picture all use the one file.
final class PNGExport: @unchecked Sendable {
    /// The picture, at full size.
    let image: CIImage

    private let lock = NSLock()
    private var task: Task<URL, any Error>?
    private var url: URL?

    // MARK: - Initializer

    init(image: CIImage) {
        self.image = image
    }

    deinit {
        if let url {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Public Helpers

    /// Starts encoding if it hasn't started, without waiting for it.
    func start() {
        _ = encoding()
    }

    /// The PNG file, once it is written.
    func file() async throws -> URL {
        try await encoding().value
    }

    // MARK: - Private Helpers

    private func encoding() -> Task<URL, any Error> {
        lock.withLock {
            if let task { return task }

            let task = Task.detached(priority: .utility) { [self] in
                do {
                    let target = URL.temporaryDirectory.appending(path: "Framed Screenshot \(UUID()).png")
                    try LayerStore.shared.pngData(of: image).write(to: target)
                    lock.withLock { self.url = target }
                    return target
                } catch {
                    // Let the next ask try again.
                    lock.withLock { self.task = nil }
                    throw error
                }
            }

            self.task = task
            return task
        }
    }
}
