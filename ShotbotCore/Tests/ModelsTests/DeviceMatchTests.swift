//
//  DeviceMatchTests.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/25/26.
//

import Testing
import UIKit
import Models

struct DeviceMatchTests {
    @Test("Every resolution matches back to its own frame", arguments: DeviceInfo.all())
    func resolutionMatchesItsFrame(device: DeviceInfo) {
        switch DeviceInfo.match(for: device.inputSize) {
        case .exact(let match):
            #expect(match.deviceFrame == device.deviceFrame)
        case .ambiguous(let matches):
            #expect(matches.contains { $0.deviceFrame == device.deviceFrame })
        case .none:
            Issue.record("\(device.deviceFrame) at \(device.inputSize) did not match")
        }
    }

    @Test("A size no device uses does not match")
    func unknownSizeDoesNotMatch() {
        guard case .none = DeviceInfo.match(for: CGSize(width: 1, height: 1)) else {
            Issue.record("Expected no match")
            return
        }
    }

    @Test("The 2018 and 2024 iPad Pro 11-inch are separate devices with their own frames and resolutions")
    func ipadProGenerationsAreSeparate() {
        let original = DeviceInfo.all().filter { $0.deviceFrame == "iPad Pro 2018 11 Inch Landscape" }
        let m4 = DeviceInfo.all().filter { $0.deviceFrame == "iPad Pro 2024 11 Inch Landscape" }

        #expect(original.map(\.inputSize) == [CGSize(width: 2388, height: 1668), CGSize(width: 2778, height: 1940)])
        #expect(m4.map(\.inputSize) == [CGSize(width: 2420, height: 1668), CGSize(width: 2816, height: 1940)])
        #expect(Set((original + m4).map(\.name)) == ["iPad Pro 2018 11 Inch", "iPad Pro 2024 11 Inch"])
        #expect(original.filter(\.isScaled).count == 1)
        #expect(m4.filter(\.isScaled).count == 1)
    }

    @Test("Phones and iPads have portrait and landscape frames, and everything else has one")
    func orientationsFollowDeviceType() {
        // Group by frame without its orientation, so models that share a frame count once.
        let byFrame = Dictionary(grouping: DeviceInfo.all()) { device in
            device.deviceFrame
                .replacingOccurrences(of: " Portrait", with: "")
                .replacingOccurrences(of: " Landscape", with: "")
        }

        for (frame, devices) in byFrame {
            let orientations = Set(devices.map(\.orientation))

            if frame.hasPrefix("iPhone") || frame.hasPrefix("iPad") {
                #expect(orientations == [.portrait, .landscape], "\(frame) needs both orientations")
            } else {
                #expect(orientations.count == 1, "\(frame) should have a single orientation")
            }
        }
    }

    @Test("Landscape screen size and offset are the portrait ones swapped")
    func landscapeGeometrySwapsPortrait() {
        for (frame, devices) in Self.devicesByFrame() {
            guard
                let portrait = devices.first(where: { $0.orientation == .portrait }),
                let landscape = devices.first(where: { $0.orientation == .landscape })
            else {
                continue
            }

            #expect(landscape.screenSize == CGSize(width: portrait.screenSize.height, height: portrait.screenSize.width), "\(frame)")

            // iPad Air 2020's landscape art is not an exact transpose of its portrait art, so it sets its own offset.
            if portrait.name != "iPad Air 2020" {
                #expect(landscape.offSet == CGPoint(x: portrait.offSet.y, y: portrait.offSet.x), "\(frame)")
            }
        }
    }

    @Test("Landscape resolutions are the portrait resolutions with width and height swapped")
    func landscapeSwapsPortrait() {
        for (frame, devices) in Self.devicesByFrame() {
            let portrait = devices.filter { $0.orientation == .portrait }
            let landscape = devices.filter { $0.orientation == .landscape }
            guard !portrait.isEmpty, !landscape.isEmpty else { continue }

            let swapped = Set(portrait.map { "\($0.name)|\($0.resolutionName)|\(Int($0.inputSize.height))x\(Int($0.inputSize.width))" })
            let actual = Set(landscape.map { "\($0.name)|\($0.resolutionName)|\(Int($0.inputSize.width))x\(Int($0.inputSize.height))" })

            #expect(swapped == actual, "\(frame)")
        }
    }

    @Test("Display names come from the device, not the frame asset")
    func displayNameUsesDeviceName() throws {
        let device = try #require(DeviceInfo.all().first { $0.deviceFrame == "iPhone 16 Pro - Black Titanium - Landscape" })

        #expect(device.displayName == "iPhone 16 Pro")
        #expect(device.orientation == .landscape)
    }

    /// Devices grouped by their frame, without the orientation, so portrait and landscape land together.
    private static func devicesByFrame() -> [String: [DeviceInfo]] {
        Dictionary(grouping: DeviceInfo.all()) { device in
            device.deviceFrame
                .replacingOccurrences(of: " Portrait", with: "")
                .replacingOccurrences(of: " Landscape", with: "")
        }
    }

    @Test("A device with several colors switches color and keeps the same mask")
    func deviceSwitchesColor() throws {
        let device = try #require(DeviceInfo.all().first { $0.deviceFrame == "iPhone 17 Pro - Silver - Portrait" })

        #expect(device.colors == ["Silver", "Cosmic Orange", "Deep Blue"])
        #expect(device.colorName == "Silver")
        #expect(device.hasColorOptions)

        let orange = device.withColor("Cosmic Orange")

        #expect(orange.deviceFrame == "iPhone 17 Pro - Cosmic Orange - Portrait")
        #expect(orange.colorName == "Cosmic Orange")
        #expect(orange.frameImage != nil)
        #expect(orange.screenMask?.width == device.screenMask?.width)
        #expect(device.withColor("Not A Color").deviceFrame == device.deviceFrame)
    }

    @Test("A device with one look has no color options")
    func singleLookHasNoColors() throws {
        let device = try #require(DeviceInfo.all().first { $0.name == "iPhone 12 Pro" })

        #expect(device.colors.isEmpty)
        #expect(device.colorName == nil)
        #expect(!device.hasColorOptions)
        #expect(device.withColor("Red").deviceFrame == device.deviceFrame)
    }

    @Test("A color whose screen is drawn elsewhere uses its own offset")
    func colorWithOwnOffset() throws {
        let device = try #require(DeviceInfo.all().first { $0.deviceFrame == "iMac M4 - Blue" })

        #expect(device.offSet == CGPoint(x: 140, y: 150))
        #expect(device.withColor("Orange").offSet == CGPoint(x: 142, y: 150))
        #expect(device.withColor("Green").offSet == CGPoint(x: 140, y: 150))
    }

    @Test("Both screens of the iPhone Duo are one device with one set of colors")
    func duoScreensShareColors() {
        let duo = DeviceInfo.all().filter { $0.name == "iPhone Duo" }

        #expect(Set(duo.compactMap(\.screenName)) == ["Inner", "Outer"])
        #expect(Set(duo.map(\.deviceFrame)).count == 4)
        #expect(Set(duo.map(\.colors)).count == 1)
        #expect(duo.first?.colors == ["Star White", "Night Sky"])
    }

    @Test("A screenshot at Apple's spec size for the Duo's inner screen is scaled to fit its frame")
    func duoAppleSpecIsScaled() throws {
        guard case .exact(let device) = DeviceInfo.match(for: CGSize(width: 1878, height: 2670)) else {
            Issue.record("Expected 1878 x 2670 to match one device")
            return
        }

        #expect(device.name == "iPhone Duo")
        #expect(device.resolutionName == "Apple Spec")
        #expect(device.screenSize == CGSize(width: 2007, height: 2853))
        #expect(device.isScaled)
    }

    @Test("An outer screen screenshot with Shift Left to the Edge is drawn at its real size, not scaled")
    func duoShiftLeftToTheEdgeIsNotScaled() throws {
        guard case .exact(let device) = DeviceInfo.match(for: CGSize(width: 1371, height: 2034)) else {
            Issue.record("Expected 1371 x 2034 to match one device")
            return
        }

        #expect(device.name == "iPhone Duo")
        #expect(device.screenName == "Outer")
        #expect(device.resolutionName == "Shift Left to the Edge")
        #expect(device.isShiftedToEdge)
        #expect(device.screenSize == CGSize(width: 1398, height: 2034))
    }

    @Test("The iPhone Duo's outer screen can be shown open as well as closed")
    func duoOuterScreenHasAnOpenView() throws {
        let closed = try #require(DeviceInfo.all().first { $0.deviceFrame == "iPhone Duo - Star White - Outer Closed Portrait" })

        #expect(closed.views == ["Closed", "Open"])
        #expect(closed.viewName == "Closed")
        #expect(closed.hasViewOptions)

        let open = closed.withView("Open")

        #expect(open.viewName == "Open")
        #expect(open.deviceFrame == "iPhone Duo - Star White - Outer Open")
        #expect(open.offSet == CGPoint(x: 1570, y: 80))
        #expect(open.screenSize == closed.screenSize)
        #expect(open.frameImage != nil)
        #expect(open.screenMask != nil)

        // The view and the color are chosen separately.
        #expect(open.withColor("Night Sky").deviceFrame == "iPhone Duo - Night Sky - Outer Open")
        #expect(closed.withColor("Night Sky").withView("Open").deviceFrame == "iPhone Duo - Night Sky - Outer Open")
        #expect(open.withView("Closed").deviceFrame == "iPhone Duo - Star White - Outer Closed Portrait")
        #expect(closed.withView("Not A View").deviceFrame == closed.deviceFrame)
    }

    @Test("Only the iPhone Duo's screens have views")
    func onlyTheDuoHasViews() {
        for device in DeviceInfo.all() {
            let expected: [String]

            switch (device.name == "iPhone Duo", device.screenName, device.orientation) {
            case (true, "Inner", _): expected = ["Open", "Partially Open"]
            case (true, "Outer", .portrait): expected = ["Closed", "Open"]
            default: expected = []
            }

            #expect(device.views == expected, "\(device.deviceFrame)")
        }
    }

    @Test("The iPhone Duo's inner screen can be partially open in both orientations")
    func duoInnerScreenHasAPartiallyOpenView() throws {
        for orientation in [DeviceOrientation.portrait, .landscape] {
            let flat = try #require(DeviceInfo.all().first {
                $0.name == "iPhone Duo" && $0.screenName == "Inner" && $0.orientation == orientation
            })
            let partiallyOpen = flat.withView("Partially Open")

            #expect(!flat.isPartiallyOpen)
            #expect(partiallyOpen.isPartiallyOpen)
            #expect(partiallyOpen.viewName == "Partially Open")

            // Partially Open bends the flat frame, so it uses the same frame, offset and mask.
            #expect(partiallyOpen.deviceFrame == flat.deviceFrame)
            #expect(partiallyOpen.offSet == flat.offSet)
            #expect(partiallyOpen.screenMask?.width == flat.screenMask?.width)
            #expect(partiallyOpen.withColor("Night Sky").deviceFrame == flat.withColor("Night Sky").deviceFrame)
        }
    }

    @Test("Each screen of a device saves its own view")
    func screensKeepSeparateViewKeys() throws {
        let inner = try #require(DeviceInfo.all().first { $0.screenName == "Inner" })
        let outer = try #require(DeviceInfo.all().first { $0.screenName == "Outer" })

        #expect(inner.viewPreferenceKey == "iPhone Duo Inner")
        #expect(outer.viewPreferenceKey == "iPhone Duo Outer")
        #expect(try #require(DeviceInfo.all().first { $0.name == "iPhone 12 Pro" }).viewPreferenceKey == "iPhone 12 Pro")
    }

    @Test("A size shared by several iPhones asks the user which one")
    func sharedSizeIsAmbiguous() {
        guard case .ambiguous(let options) = DeviceInfo.match(for: CGSize(width: 1206, height: 2622)) else {
            Issue.record("Expected 1206 x 2622 to be ambiguous")
            return
        }

        #expect(Set(options.map(\.name)) == ["iPhone 16 Pro", "iPhone 17", "iPhone 17 Pro", "iPhone 18 Pro"])
    }
}
