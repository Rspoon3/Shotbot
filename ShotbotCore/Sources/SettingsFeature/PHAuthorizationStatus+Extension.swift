//
//  PHAuthorizationStatus+Extension.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/23/23.
//

import Foundation
import Photos


extension PHAuthorizationStatus {
    var title: String {        
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .limited:
            return "Limited"
        @unknown default:
            return "Unknown"
        }
    }
}
