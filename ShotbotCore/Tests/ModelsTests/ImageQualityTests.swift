//
//  ImageQualityTests.swift
//  ShotbotTests
//
//  Created by Richard Witherspoon on 5/20/23.
//

import Foundation
import XCTest
import Models

final class ImageQualityTests: XCTestCase {
    
    // MARK: - Tests
    
    func testValue() {
        XCTAssertEqual(ImageQuality.original.value, 1)
        XCTAssertEqual(ImageQuality.high.value, 0.8)
        XCTAssertEqual(ImageQuality.medium.value, 0.6)
        XCTAssertEqual(ImageQuality.low.value, 0.4)
        XCTAssertEqual(ImageQuality.poor.value, 0.2)
    }
    
    func testID() {
        for quality in ImageQuality.allCases {
            XCTAssertEqual(quality.rawValue, quality.id)
        }
    }
}
