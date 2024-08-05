//
//  Bundle+Extension.swift
//  NYAB Field Service
//
//  Created by Richard Witherspoon on 3/23/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI
import Models

public extension Bundle {    
    static let appTitle   = main.infoDictionary?["CFBundleName"] as? String
    static let appVersion = main.infoDictionary?["CFBundleShortVersionString"] as? String
    static let appBuild   = main.infoDictionary?["CFBundleVersion"] as? String
        
    enum IconType {
        case current, primary, alternative(named: String)
    }
    
    static func appIcon(type: IconType) -> PlatformImage? {
        // First will be smallest for the device class, last will be the largest for device class
        switch type{
        case .current:
//            if let currentAlternativeIconName = UIApplication.shared.alternateIconName {
//                return getAlternateAppIcon(named: currentAlternativeIconName)
//            } else {
                return getPrimaryAppIcon()
//            }
        case .primary:
            return getPrimaryAppIcon()
        case .alternative(let iconName):
            return getAlternateAppIcon(named: iconName)
        }
    }
    
    static private func getPrimaryAppIcon()->PlatformImage?{
        guard
            let iconsDictionary = main.infoDictionary?["CFBundleIcons"] as? NSDictionary,
            let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? NSDictionary,
            let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? NSArray,
            let lastIcon = iconFiles.lastObject as? String
        else {
            return nil
        }
        
        return PlatformImage(named: lastIcon)
    }
    
    static private func getAlternateAppIcon(named iconName: String)->PlatformImage?{
        guard
            let iconsDictionary = main.infoDictionary?["CFBundleIcons"] as? NSDictionary,
            let alternativeIconsDictionary = iconsDictionary["CFBundleAlternateIcons"] as? NSDictionary,
            let alternativeIconDictionary = alternativeIconsDictionary[iconName] as? NSDictionary,
            let iconFiles = alternativeIconDictionary["CFBundleIconFiles"] as? NSArray,
            let lastIcon = iconFiles.lastObject as? String
        else {
            return nil
        }
        
        return PlatformImage(named: lastIcon)
    }
}
