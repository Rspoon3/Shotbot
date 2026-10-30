//
//  DeviceInfoTests.swift
//  ShotbotTests
//
//  Created by Richard Witherspoon on 4/23/23.
//

import XCTest
import Models

final class DeviceInfoTests: XCTestCase {
    func testNoDeviceListsTheSameFrameAndSizeTwice() {
        let grouped = Dictionary(grouping: DeviceInfo.all(), by: \.inputSize)

        // Different devices may share a screenshot size, such as the iPhone 16 Pro and 17 Pro. The user picks one.
        for (size, devices) in grouped {
            XCTAssertEqual(
                Set(devices.map(\.deviceFrame)).count,
                devices.count,
                "\(size) is listed more than once for \(devices.map(\.deviceFrame))"
            )
        }
    }

    func testNumberOfDevices() {
        XCTAssertEqual(DeviceInfo.all().count, 112)
    }

    func testAllDeviceFramesHaveAnAsset() {
        for device in DeviceInfo.all() {
            // Every color of every device needs its own frame.
            for variant in device.hasColorOptions ? device.colors.map(device.withColor) : [device] {
                XCTAssertNotNil(variant.frameImage, variant.deviceFrame)
            }
        }
    }
}
