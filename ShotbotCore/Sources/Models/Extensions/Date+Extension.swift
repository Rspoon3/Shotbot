//
//  Date+Extension.swift
//  
//
//  Created by Richard Witherspoon on 6/29/23.
//

import Foundation

public extension Date {
    func adding(_ value: Int, _ component: Calendar.Component) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: self)!
    }
    
    func subtracting(_ value: Int, _ component: Calendar.Component) -> Date {
        adding(-value, component)
    }
}
