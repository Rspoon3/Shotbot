//
//  CGSize+Extension.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 7/19/24.
//

import Foundation

extension CGSize {
    var aspectRatio: CGFloat {
        guard width != 0 else { return 0 }
        return height / width
    }
    
    static func * (lhs: CGSize, scalar: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * scalar, height: lhs.height * scalar)
    }
}
