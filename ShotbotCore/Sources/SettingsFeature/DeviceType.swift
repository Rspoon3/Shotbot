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
                "iPhone SE (3rd generation)",
                "iPhone SE (2nd generation)",
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
                "iPad Pro 12.9-in. (6th generation)",
                "iPad Pro 12.9-in. (5th generation)",
                "iPad Pro 12.9-in. (4th generation)",
                "iPad Pro 12.9-in. (3rd generation)",
                "iPad Pro 12.9-in. (2nd generation)",
                "iPad Pro 12.9-in. (1st generation)",
                "iPad Pro 11-in. (3rd generation)",
                "iPad Pro 11-in. (2nd generation)",
                "iPad Pro 11-in. (1st generation)",
                "iPad Air (5th generation)",
                "iPad Air (4th generation)",
                //"iPad Air (3rd generation)", Not supported
                //"iPad Air (2nd generation)", Not supported
                //"iPad Air (1st generation)", Not supported

                "iPad (9th generation)",
                "iPad (8th generation)",
                "iPad (7th generation)",
                //"iPad (6th generation)", Not supported
                //"iPad (5th generation)", Not supported
                //"iPad (4th generation)", Not supported
                //"iPad (3rd generation)", Not supported
                //"iPad 2", Not supported
                //"iPad (1st generation)", Not supported
                
                "iPad Mini (6th generation)"
                //"iPad Mini (5th generation)", Not supported
                //"iPad Mini 4", Not supported
                //"iPad Mini 3", Not supported
                //"iPad Mini 2", Not supported
                //"iPad Mini (1st generation)", Not supported
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
                "Apple Watch Ultra 2",
                "Apple Watch Ultra",
                "Apple Watch Series 9, 41/45mm",
                "Apple Watch Series 8, 41/45mm",
                "Apple Watch Series 7, 41/45mm",
                "Apple Watch Series 6, 40/44mm",
                "Apple Watch Series 5, 40/44mm",
                "Apple Watch Series 4, 40/44mm",
                //"Apple Watch Series 3, 38/42mm", Not supported
                //"Apple Watch Series 2, 38/42mm", Not supported
                //"Apple Watch Series 1, 38/42mm", Not supported
                "Apple Watch SE (2nd generation), 40/44mm",
                "Apple Watch SE (1st generation), 40/44mm",
            ]
        }
    }
}
