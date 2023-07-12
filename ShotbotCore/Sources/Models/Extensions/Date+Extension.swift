//
//  Date+Extension.swift
//  
//
//  Created by Richard Witherspoon on 6/29/23.
//

import Foundation

public extension Date {
    func adding(days:Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
    
    func subtracting(hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: -hours, to: self) ?? self
    }
}
