//
//  DeviceType.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import Foundation

enum DeviceType: String, CaseIterable, Identifiable {
    case iPhone = "iPhones"
    case iPad = "iPads"
    case mac = "Macs"
    case appleWatch = "Apple Watches"
    
    var id: String { rawValue }
    
    var supportedDevices: [String] {
        switch self {
        case .iPhone:
            return [
                "iPhone 15 Pro Max",
                "iPhone 15 Pro",
                "iPhone 14 Pro Max",
                "iPhone 14 Pro",
                "iPhone 14",
                "iPhone 13 Pro Max",
                "iPhone 13",
                "iPhone 13 Mini",
                "iPhone 12 Pro Max",
                "iPhone 12",
                "iPhone 12 Mini",
                "iPhone SE (3rd Generation)",
                "iPhone SE (2nd Generation)",
                "iPhone 11 Pro Max",
                "iPhone 11 Pro",
                "iPhone 11",
                "iPhone X",
                "iPhone XR",
                "iPhone 8 Plus",
                "iPhone 8",
                "iPhone 7 Plus",
                "iPhone 7",
                "iPhone 6 Plus",
                "iPhone 6",
            ]
        case .iPad:
            return [
                "iPad Pro 2018 11 Inch",
                "iPad Pro 2018 12.9 Inch",
                "iPad Air 2020",
                "iPad 9th Generation",
                "iPad Mini 6th Generation"
            ]
        case .mac:
            return [
                "MacBook Pro 2021 16 Inch",
                "MacBook Pro 2021 14 Inch",
                "MacBook Pro 13 Inch",
                "MacBook Air 2022 13",
                "MacBook Air 2020",
                "iMac 2021 24 Inch"
            ]
        case .appleWatch:
            return [
                "Watch Ultra 2022",
                "Watch Series 7, 45mm",
                "Watch Series 7, 41mm",
                "Watch Series 4, 44mm",
                "Watch Series 4, 40mm",
            ]
        }
    }
}
