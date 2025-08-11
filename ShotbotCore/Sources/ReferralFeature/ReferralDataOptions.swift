//
//  ReferralDataOptions.swift
//  Shotbot
//

import Foundation

public struct ReferralDataOptions: OptionSet, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let codes = ReferralDataOptions(rawValue: 1 << 0)
    public static let rules = ReferralDataOptions(rawValue: 1 << 1)
    public static let rewards = ReferralDataOptions(rawValue: 1 << 2)
    public static let referrals = ReferralDataOptions(rawValue: 1 << 3)
    
    public static let all: ReferralDataOptions = [.codes, .rules, .rewards, .referrals]
    
    public var description: String {
        var components: [String] = []
        
        if contains(.codes) {
            components.append("codes")
        }
        if contains(.rules) {
            components.append("rules")
        }
        if contains(.rewards) {
            components.append("rewards")
        }
        if contains(.referrals) {
            components.append("referrals")
        }
        
        return components.joined(separator: ", ")
    }
}
