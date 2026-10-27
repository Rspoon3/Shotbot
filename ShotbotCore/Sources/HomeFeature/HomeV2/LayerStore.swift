//
//  LayerStore.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage
import Metal
import Models
import UIKit

/// Builds and remembers the expensive layers of a framed screenshot.
///
/// A layer is drawn once at full size into a GPU-backed buffer and then reused, so changing something small, like the
/// device's color, only redraws the layer that depends on it:
/// - The screen layer, the screenshot scaled and clipped into place, depends on the screenshot and the screen's shape.
/// - The device layer, the frame over the screen layer, depends on the frame's color.
/// - The shadow depends only on the device layer.
final class LayerStore: @unchecked Sendable {
    /// The one store the app uses.
    static let shared = LayerStore()

    /// The Core Image context all layers are drawn with. It shares a Metal queue with the preview.
    let context: CIContext
    let metalDevice: MTLDevice?
    let commandQueue: MTLCommandQueue?

    private let layers = NSCache<NSString, Layer>()
    private let displayP3 = CGColorSpace(name: CGColorSpace.displayP3)!
    private let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

    /// A cached image, with its size in memory so the cache can stay within its budget.
    private final class Layer {
        let image: CIImage
        let shadow: CIImage?

        init(image: CIImage, shadow: CIImage? = nil) {
            self.image = image
            self.shadow = shadow
        }
    }

    // MARK: - Initializer

    private init() {
        metalDevice = MTLCreateSystemDefaultDevice()
        commandQueue = metalDevice?.makeCommandQueue()

        if let commandQueue {
            context = CIContext(mtlCommandQueue: commandQueue)
        } else {
            context = CIContext()
        }

        layers.totalCostLimit = 700_000_000

        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [layers] _ in
            layers.removeAllObjects()
        }
    }

    // MARK: - Public Helpers

    /// The layers for one screenshot in one device, drawing whichever are not cached yet.
    /// - Parameters:
    ///   - id: Identifies the screenshot.
    ///   - screenshot: The screenshot.
    ///   - device: The device, in the color and view to draw.
    func deviceRender(id: UUID, screenshot: UIImage, device: DeviceInfo) throws -> DeviceRender {
        let key = "device|\(screenKey(id: id, device: device))|\(device.deviceFrame)" as NSString

        if let cached = layers.object(forKey: key) {
            return DeviceRender(device: cached.image, shadow: cached.shadow)
        }

        let screen = try screenLayer(id: id, screenshot: screenshot, device: device)
        let frame = try frameImage(for: device)
        let flat = frame.composited(over: screen).cropped(to: frame.extent)

        let render: DeviceRender

        if device.isPartiallyOpen, let angle = device.openingAngle {
            render = try foldedRender(of: flat, openingAngle: angle)
        } else {
            let baked = try bake(flat, extent: flat.extent)
            render = DeviceRender(device: baked, shadow: try bake(shadow(of: baked), extent: shadowExtent(of: baked)))
        }

        layers.setObject(Layer(image: render.device, shadow: render.shadow), forKey: key, cost: cost(of: render))
        return render
    }

    /// Draws an image once, so it can be used many times without being worked out again.
    func baked(_ image: CIImage) throws -> CIImage {
        try bake(image, extent: image.extent)
    }

    /// The layers of a device with a plain screen, for its outline and shadow when the screen's content changes.
    func silhouette(of device: DeviceInfo) throws -> DeviceRender {
        let size = device.inputSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let solid = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        return try deviceRender(id: Self.silhouetteID, screenshot: solid, device: device)
    }

    private static let silhouetteID = UUID()

    /// A scene image as PNG data, at the size it was composed at.
    func pngData(of image: CIImage) throws -> Data {
        guard let data = context.pngRepresentation(of: image, format: .RGBA8, colorSpace: sRGB) else {
            throw LayerStoreError.exportFailed
        }

        return data
    }

    // MARK: - Private Helpers

    enum LayerStoreError: LocalizedError {
        case missingFrame
        case bufferFailed
        case exportFailed

        var errorDescription: String? {
            switch self {
            case .missingFrame: "The device frame couldn't be loaded."
            case .bufferFailed: "There wasn't enough memory to draw the image."
            case .exportFailed: "The image couldn't be exported."
            }
        }
    }

    /// What the screen layer depends on: the screenshot and the shape of the screen, but not the frame's color.
    private func screenKey(id: UUID, device: DeviceInfo) -> String {
        "\(id.uuidString)|\(device.name)|\(device.screenName ?? "")|\(device.orientation)|\(device.resolutionName)|\(device.viewName ?? "")"
    }

    private func frameImage(for device: DeviceInfo) throws -> CIImage {
        let key = "frame|\(device.deviceFrame)" as NSString

        if let cached = layers.object(forKey: key) {
            return cached.image
        }

        guard let cgImage = device.frameImage?.cgImage else { throw LayerStoreError.missingFrame }

        let image = CIImage(cgImage: cgImage)
        layers.setObject(Layer(image: image), forKey: key, cost: cgImage.bytesPerRow * cgImage.height)
        return image
    }

    /// The screenshot scaled to the screen, clipped to its rounded corners, and placed where the frame has its screen.
    private func screenLayer(id: UUID, screenshot: UIImage, device: DeviceInfo) throws -> CIImage {
        let key = "screen|\(screenKey(id: id, device: device))" as NSString

        if let cached = layers.object(forKey: key) {
            return cached.image
        }

        let frame = try frameImage(for: device)
        let frameSize = frame.extent.size

        guard let source = CIImage(image: screenshot) else { throw LayerStoreError.bufferFailed }

        var screen = source
            .transformed(by: CGAffineTransform(translationX: -source.extent.minX, y: -source.extent.minY))
            .transformed(by: CGAffineTransform(
                scaleX: device.screenSize.width / source.extent.width,
                y: device.screenSize.height / source.extent.height
            ))

        if let mask = device.screenMask {
            // The mask is gray, so its brightness is turned into the alpha the blend reads.
            screen = screen.applyingFilter("CIBlendWithAlphaMask", parameters: [
                kCIInputBackgroundImageKey: CIImage.empty(),
                kCIInputMaskImageKey: CIImage(cgImage: mask).applyingFilter("CIMaskToAlpha")
            ])
        }

        // Core Image's origin is the bottom-left, while the offset is measured from the top-left.
        screen = screen.transformed(by: CGAffineTransform(
            translationX: device.offSet.x,
            y: frameSize.height - device.offSet.y - device.screenSize.height
        ))

        let baked = try bake(screen.cropped(to: frame.extent), extent: frame.extent)
        layers.setObject(Layer(image: baked), forKey: key, cost: bytes(of: frame.extent))
        return baked
    }

    /// Folds a flat device. The fold draws its own shadow, on a canvas larger than the device.
    private func foldedRender(of flat: CIImage, openingAngle: Double) throws -> DeviceRender {
        guard
            let cgImage = context.createCGImage(flat, from: flat.extent),
            let folded = UIImage(cgImage: cgImage).partiallyOpened(openingAngle: openingAngle),
            let foldedCI = CIImage(image: folded)
        else {
            throw LayerStoreError.bufferFailed
        }

        return DeviceRender(device: try bake(foldedCI, extent: foldedCI.extent), shadow: nil)
    }

    /// A soft shadow below a device, from the device's outline.
    private func shadow(of device: CIImage) -> CIImage {
        let extent = device.extent

        return device
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.4)
            ])
            .clampedToExtent()
            .applyingGaussianBlur(sigma: extent.width * 0.014)
            .transformed(by: CGAffineTransform(translationX: 0, y: -extent.height * 0.014))
    }

    private func shadowExtent(of device: CIImage) -> CGRect {
        device.extent.insetBy(dx: -device.extent.width * 0.08, dy: -device.extent.height * 0.08)
    }

    /// Draws an image once into a buffer that stays on the GPU, and returns an image that reads from the buffer.
    private func bake(_ image: CIImage, extent: CGRect) throws -> CIImage {
        let width = Int(extent.width.rounded(.up))
        let height = Int(extent.height.rounded(.up))
        var buffer: CVPixelBuffer?

        CVPixelBufferCreate(
            nil,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferIOSurfacePropertiesKey: [:],
                kCVPixelBufferMetalCompatibilityKey: true
            ] as CFDictionary,
            &buffer
        )

        guard let buffer else { throw LayerStoreError.bufferFailed }

        context.render(image, to: buffer, bounds: extent, colorSpace: displayP3)

        return CIImage(cvPixelBuffer: buffer, options: [.colorSpace: displayP3])
            .transformed(by: CGAffineTransform(translationX: extent.minX, y: extent.minY))
    }

    private func bytes(of extent: CGRect) -> Int {
        Int(extent.width * extent.height) * 4
    }

    private func cost(of render: DeviceRender) -> Int {
        bytes(of: render.device.extent) + (render.shadow.map { bytes(of: $0.extent) } ?? 0)
    }
}
