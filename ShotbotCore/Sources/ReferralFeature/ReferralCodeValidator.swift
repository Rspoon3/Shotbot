//
//  ReferralCodeValidator.swift
//  Shotbot
//

import Foundation
import ReferralService

public struct ReferralCodeValidator {
    let codeRules: CodeRules?
    
    public init(codeRules: CodeRules?) {
        self.codeRules = codeRules
    }
    
    public func validate(_ code: String) -> ValidationResult {
        guard !code.isEmpty else {
            return ValidationResult(isValid: false, message: "Please enter a referral code")
        }
        
        guard let rules = codeRules else {
            return ValidationResult(isValid: true, message: nil)
        }
        
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedCode.count < rules.minLength {
            return ValidationResult(
                isValid: false,
                message: "Code must be at least \(rules.minLength) characters"
            )
        }
        
        if trimmedCode.count > rules.maxLength {
            return ValidationResult(
                isValid: false,
                message: "Code must be no more than \(rules.maxLength) characters"
            )
        }
        
        if rules.requiresUppercase && !trimmedCode.contains(where: { $0.isUppercase }) {
            return ValidationResult(
                isValid: false,
                message: "Code must contain at least one uppercase letter"
            )
        }
        
        if rules.requiresNumbers && !trimmedCode.contains(where: { $0.isNumber }) {
            return ValidationResult(
                isValid: false,
                message: "Code must contain at least one number"
            )
        }
        
        if let pattern = rules.pattern {
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
            if !predicate.evaluate(with: trimmedCode) {
                return ValidationResult(
                    isValid: false,
                    message: "Invalid code format"
                )
            }
        }
        
        return ValidationResult(isValid: true, message: nil)
    }
    
    public struct ValidationResult {
        public let isValid: Bool
        public let message: String?
    }
}