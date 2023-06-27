//
//  DeviceInfoTests.swift
//  ShotbotTests
//
//  Created by Richard Witherspoon on 4/23/23.
//

import XCTest
import Models

final class DeviceInfoTests: XCTestCase {    
    func testAllDeviceInputSizesAreUnique() {
        let inputSizes = DeviceInfo.all().map(\.inputSize)
        let set = Set(inputSizes)
        XCTAssertEqual(inputSizes.count, set.count)
    }
    
    func testAllDeviceFramesAreUnique() {
        let deviceFrames = DeviceInfo.all().map(\.deviceFrame)
        let frames = Set(deviceFrames)
        XCTAssertEqual(deviceFrames.count, frames.count)
    }
    
    func testNumberOfDevices() {
        XCTAssertEqual(DeviceInfo.all().count, 39)
    }
    
    func testAllDeviceFramesHaveAnAsset() {
        for device in DeviceInfo.all() {
            let image = UIImage(named: device.deviceFrame, in: .models, compatibleWith: nil)

            XCTAssertNotNil(image)
            
            if device.mergeMethod == .islandOverlay {
                let title = "\(device.deviceFrame) Without Island"
                let islandImage = UIImage(named: title, in: .models, compatibleWith: nil)

                XCTAssertNotNil(islandImage)
            }
        }
    }
}
