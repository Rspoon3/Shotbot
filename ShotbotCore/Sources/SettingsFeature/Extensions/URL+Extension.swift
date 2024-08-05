//
//  URL+Extension.swift
//  
//
//  Created by Richard Witherspoon on 8/5/21.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public extension URL {
#if os(macOS)
    static let appSettings = URL(string: "https://github.com/Rspoon3/Shotbot")!
#else
    static let appSettings = URL(string: UIApplication.openSettingsURLString)!
#endif
    
    static let gitHub   = URL(string: "https://github.com/Rspoon3/Shotbot")!
    static let personal = URL(string: "https://www.rspoon3.com")!
    static let mastodon = URL(string: "https://mastodon.social/@rwitherspoon")!
    static let termsAndConditions = URL(string: "https://github.com/Rspoon3/Shotbot/blob/main/TERMS.MD")!

    static func twitter(username: String)-> URL {
        URL(string: "https://twitter.com/\(username)")!
    }
    
    static func instagram(username: String)-> URL{
        URL(string: "https://www.instagram.com/\(username)")!
    }
    
    static func appStoreReview(appID: Int)->URL {
        URL(string: "https://itunes.apple.com/app/appName/id\(appID)?mt=8&action=write-review")!
    }
    
    static func appStore(appID: Int)->URL {
        URL(string: "https://itunes.apple.com/app/appName/id\(appID)")!
    }
}
