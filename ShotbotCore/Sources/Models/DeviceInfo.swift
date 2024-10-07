//
//  DeviceInfo.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

import UIKit

public struct DeviceInfo: Decodable {
    public let deviceFrame: String
    public let mergeMethod: MergeMethod
    public let clipEdgesAmount: CGFloat?
    public let cornerRadius: CGFloat?
    public let inputSize: CGSize
    public let scaledSize: CGSize?
    public let offSet: CGPoint?
    
    // MARK: - Initializer
    
    public init(
        deviceFrame: String,
        mergeMethod: MergeMethod,
        clipEdgesAmount: CGFloat?,
        cornerRadius: CGFloat?,
        inputSize: CGSize,
        scaledSize: CGSize?,
        offSet: CGPoint?
    ) {
        self.deviceFrame = deviceFrame
        self.mergeMethod = mergeMethod
        self.clipEdgesAmount = clipEdgesAmount
        self.inputSize = inputSize
        self.scaledSize = scaledSize
        self.offSet = offSet
        self.cornerRadius = cornerRadius
    }
    
    // MARK: - Functions
    
    public func framed(using screenshot: UIImage) -> UIImage? {
        var screenshot = screenshot
        let offSet = offSet ?? .zero
        
        guard let frameImage = UIImage(named: deviceFrame, in: .module, with: nil) else {
            return nil
        }
        
        if let clipEdgesAmount {
            screenshot = screenshot.clipEdges(amount: clipEdgesAmount)
        } else if let cornerRadius {
            screenshot = screenshot.withRoundedCorners(radius: cornerRadius)
        }
        
        if let scaledSize {
            screenshot = screenshot.resized(to: scaledSize)
        }
        
        switch mergeMethod {
        case .singleOverlay:
            return frameImage.merge(with: screenshot, offset: offSet)
        case .singleOverlayV2:
            return screenshot.overlayWithLargerCenteredImage(frameImage)
        case .doubleOverlay:
            let image = frameImage.merge(with: screenshot, offset: offSet)
            return image.merge(with: frameImage, offset: .zero)
        case .islandOverlay:
            guard let noIsland = UIImage(named: "\(deviceFrame) Without Island", in: .module, with: nil) else {
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
