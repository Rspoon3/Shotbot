//
//  FormatStyle+Extension.swift
//  
//
//  Created by Richard Witherspoon on 7/26/23.
//

import Foundation

/// A date format to be used for logging.
///
/// ```07/25/23, 2:53:01.836 PM```
extension FormatStyle where Self == Date.FormatStyle {
    public static var log: Date.FormatStyle {
        .dateTime
            .day()
            .month(.twoDigits)
            .year(.twoDigits)
            .hour()
            .minute()
            .second()
            .secondFraction(.fractional(3))
    }
}
