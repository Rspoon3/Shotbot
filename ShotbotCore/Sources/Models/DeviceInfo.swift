//
//  DeviceInfo.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct DeviceInfo: Decodable {
    public let deviceFrame: String
    public let mergeMethod: MergeMethod
    public let clipEdgesAmount: CGFloat?
    public let inputSize: CGSize
    public let scaledSize: CGSize?
    public let offSet: CGPoint
    
    // MARK: - Initializer
    
    public init(
        deviceFrame: String,
        mergeMethod: MergeMethod,
        clipEdgesAmount: CGFloat?,
        inputSize: CGSize,
        scaledSize: CGSize?,
        offSet: CGPoint
    ) {
        self.deviceFrame = deviceFrame
        self.mergeMethod = mergeMethod
        self.clipEdgesAmount = clipEdgesAmount
        self.inputSize = inputSize
        self.scaledSize = scaledSize
        self.offSet = offSet
    }
    
    // MARK: - Functions
    
    public func framed(using screenshot: PlatformImage) -> PlatformImage? {
        var screenshot = screenshot
        
        guard let frameImage = PlatformImage(named: deviceFrame, in: .module) else {
            return nil
        }
        
        if let clipEdgesAmount {
            screenshot = screenshot.clipEdges(amount: clipEdgesAmount)
        }
        
        if let scaledSize {
            screenshot = screenshot.resized(to: scaledSize)
        }
        
        switch mergeMethod {
        case .singleOverlay:
            return frameImage.merge(with: screenshot, offset: offSet)
        case .doubleOverlay:
            let image = frameImage.merge(with: screenshot, offset: offSet)
            return image.merge(with: frameImage, offset: .zero)
        case .islandOverlay:
            guard let noIsland = PlatformImage(named: "\(deviceFrame) Without Island", in: .module) else {
                return nil
            }
            
            let noIslandFrame = noIsland.merge(with: screenshot, offset: offSet)
            
            return noIslandFrame.merge(with: frameImage, offset: .zero)
        }
    }
    
    // MARK: - Data
    
    public static func all() -> [DeviceInfo] {
        let bundle = Bundle.module
        
        let iPhoneFrames = bundle.decode([DeviceInfo].self, from: "iPhoneFrames.json")
        let iPadFrames = bundle.decode([DeviceInfo].self, from: "iPadFrames.json")
        let macFrames = bundle.decode([DeviceInfo].self, from: "MacFrames.json")
        let AppleWatchFrames = bundle.decode([DeviceInfo].self, from: "AppleWatchFrames.json")
        
        return iPhoneFrames + iPadFrames + macFrames + AppleWatchFrames
    }
}
