//
//  DeleteLatestScreenshotIntent.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 7/20/24.
//
import AppIntents
import MediaManager

struct DeleteLatestScreenshotIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete"
    static var isDiscoverable: Bool = false
    
    @Parameter(title: "AssetID")
    var assetID: String?
    
    // MARK: - Initializers
    
    init(assetID: String) {
        self.assetID = assetID
    }
    
    init() {}
    
    // MARK: - Public

    func perform() async throws -> some IntentResult {
        guard let assetID else { return .result() }
        try await PhotoLibraryManager.live.delete([assetID])
        return .result()
    }
}
