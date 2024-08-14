//
//  UIGraphicsImageRendererFormat+Extension.swift
//  ShotbotCore
//
//  Created by Richard Witherspoon on 8/4/24.
//

import UIKit
import AVFoundation

extension UIGraphicsImageRendererFormat {
    convenience init(scale: Int) {
        self.init()
        self.scale = 1
    }
    
    static let singleScale = UIGraphicsImageRendererFormat(scale: 1)
}
