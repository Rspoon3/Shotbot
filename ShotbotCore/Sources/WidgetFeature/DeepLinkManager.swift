//
//  DeepLinkManager.swift
//
//
//  Created by Richard Witherspoon on 7/22/24.
//

import Foundation

public struct DeepLinkManager {
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public
    
    public func deepLink(from url: URL) throws -> DeepLink {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let host = components.host,
            let deepLink = DeepLink(rawValue: host)
        else {
            throw DeepLinkManagerError.badDeepLinkURL
        }
        
        return deepLink
    }
        
    // MARK: - Internal
    
    internal func deepLinkValue(from url: URL) throws -> String {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let value = components.queryItems?.first?.value
        else {
            throw DeepLinkManagerError.badDeepLinkURL
        }
        
        return value
    }
    
    // MARK: - Errors
    
    public struct DeepLinkManagerError: LocalizedError {
        public let errorDescription: String?
        public let recoverySuggestion: String?
        
        public static let badDeepLinkURL = Self(
            errorDescription: "Corrupt deeplink",
            recoverySuggestion: "An issue occurred opening the deeplink"
        )
    }
}
