//
//  ReferralCodeValidator.swift
//  Shotbot
//

import Foundation
import ReferralService

/// Handles validation logic for referral code input
public struct ReferralCodeValidator {
    private let codeRules: CodeRules?
    
    /// Gets the maximum allowed length
    var maxLength: Int? {
        return codeRules?.maxLength
    }
    
    // MARK: - Initializer
    
    public init(codeRules: CodeRules?) {
        self.codeRules = codeRules
    }
    
    // MARK: - Public
    
    /// Determines if the submit button should be disabled based on input validation
    func shouldDisableSubmit(for input: String, isLoading: Bool) -> Bool {
        return isLoading || !isValidLength(input) || !hasValidCharacters(input) || input.isEmpty
    }
    
    /// Validates if the code length is within the allowed range
    func isValidLength(_ code: String) -> Bool {
        guard let codeRules else { return true }
        return (codeRules.minLength...codeRules.maxLength).contains(code.count)
    }
    
    /// Validates if the input contains only valid characters (letters, numbers, and allowed special characters)
    func hasValidCharacters(_ input: String) -> Bool {
        guard let codeRules else {
            return input.allSatisfy { $0.isLetter || $0.isNumber }
        }
        
        let allowedSpecialChars = Set(codeRules.allowedSpecialCharacters)
        return input.allSatisfy { character in
            character.isLetter ||
            character.isNumber ||
            allowedSpecialChars.contains(String(character))
        }
    }
}
