//
//   UserDefaults+Extension.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 5/20/23.
//

import Foundation

extension UserDefaults {
    public static var shared: UserDefaults {
        return UserDefaults(suiteName: "group.com.rspoon3.ShotbotFrames")!
    }
}
