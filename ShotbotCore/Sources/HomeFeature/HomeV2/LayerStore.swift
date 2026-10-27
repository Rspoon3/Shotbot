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

/// Builds the expensive layers of a framed screenshot and keeps them in a `LayerCache`.
///
/// A layer is drawn once at full size into a GPU-backed buffer and then reused, so changing something small, like the
/// device's color, only redraws the layer that depends on it:
/// - The screen layer, the screenshot scaled and clipped into place, depends on the screenshot and the screen's shape.
/// - The frame, the device's art in its color, is drawn once per color.
/// - The shadow depends only on the device's outline, so every color of a device shares one.
/// - The device is the frame over the screen layer. It is left undrawn, since putting two finished layers together costs
///   almost nothing, so a color change doesn't redraw anything large.
/// - Backgrounds that are slow to draw, like a blurred photo, are drawn once per size.
final class LayerStore: @unchecked Sendable {
    /// The one store the app uses.
    static let shared = LayerStore()

    /// The Core Image context all layers are drawn with. It shares a Metal queue with the preview.
    let context: CIContext
    let metalDevice: MTLDevice?
    let commandQueue: MTLCommandQueue?

    private let layers = LayerCache(budget: 700_000_000)
    private let displayP3 = CGColorSpace(name: CGColorSpace.displayP3)!
    private let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
    private let linearGray = CGColorSpace(name: CGColorSpace.linearGray)!

    /// How dark the darkest part of a shadow is.
    private static let shadowOpacity = 0.4

    // MARK: - Initializer

    private init() {
        metalDevice = MTLCreateSystemDefaultDevice()
        commandQueue = metalDevice?.makeCommandQueue()

        if let commandQueue {
            context = CIContext(mtlCommandQueue: commandQueue)
        } else {
            context = CIContext()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [layers] _ in
            Task { await layers.removeAll() }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [layers] _ in
            Task { await layers.removeAll() }
        }
    }

    // MARK: - Public Helpers

    /// The layers for one screenshot in one device, drawing whichever are not cached yet.
    /// - Parameters:
    ///   - id: Identifies the screenshot.
    ///   - screenshot: The screenshot.
    ///   - device: The device, in the color and view to draw.
    func deviceRender(id: UUID, screenshot: UIImage, device: DeviceInfo) async throws -> DeviceRender {
        let screen = try await screenLayer(id: id, screenshot: screenshot, device: device)
        let frame = try await frameImage(for: device)
        let flat = frame.composited(over: screen).cropped(to: frame.extent)

        guard device.isPartiallyOpen, let angle = device.openingAngle else {
            return DeviceRender(device: flat, shadow: try await shadow(for: device))
        }

        // The fold goes through the CPU, so it is drawn once and kept.
        let key = "folded|\(screenKey(id: id, device: device))|\(device.deviceFrame)"

        let layer = try await layers.layer(for: key) { [self] in
            let screen = try await screenLayer(id: id, screenshot: screenshot, device: device)
            let frame = try await frameImage(for: device)
            let render = try foldedRender(of: frame.composited(over: screen).cropped(to: frame.extent), openingAngle: angle)

            return CachedLayer(image: render, cost: bytes(of: render.extent))
        }

        return DeviceRender(device: layer.image, shadow: nil)
    }

    /// Draws an image once, so it can be used many times without being worked out again.
    func baked(_ image: CIImage) throws -> CIImage {
        try bake(image, extent: image.extent)
    }

    /// What identifies a background that is slow enough to draw that it is worth keeping, or `nil` for one that isn't.
    /// - Parameters:
    ///   - style: The background.
    ///   - size: The size it fills.
    ///   - blur: How much the photo background is blurred.
    ///   - sourceKey: What the blurred style is made from.
    static func backgroundKey(_ style: BackgroundStyle, size: CGSize, blur: BackgroundBlur, sourceKey: String) -> String? {
        let shape = "\(Int(size.width))x\(Int(size.height))"

        switch style {
        case .photo: return "background|photo|\(shape)|\(blur.rawValue)"
        case .blurred: return "background|blurred|\(shape)|\(sourceKey)"
        default: return nil
        }
    }

    /// A background drawn once at one size, for the styles that are slow to draw.
    /// - Parameters:
    ///   - style: The background. Styles that are fast to draw are drawn without being kept.
    ///   - size: The size to fill, in whole pixels.
    ///   - blur: How much to blur the photo style.
    ///   - source: The picture the blurred style is made from.
    ///   - sourceKey: What identifies `source`.
    func background(_ style: BackgroundStyle, size: CGSize, blur: BackgroundBlur, source: CIImage?, sourceKey: String) async throws -> CIImage {
        guard let key = Self.backgroundKey(style, size: size, blur: blur, sourceKey: sourceKey) else {
            return BackgroundRenderer.image(style, size: size, blurSource: source, blur: blur)
        }

        let input = Unchecked(source)

        let layer = try await layers.layer(for: key) { [self] in
            let drawn = BackgroundRenderer.image(style, size: size, blurSource: input.value, blur: blur)
            return CachedLayer(image: try bake(drawn, extent: drawn.extent), cost: bytes(of: drawn.extent))
        }

        return layer.image
    }

    /// The layers of a device with a plain screen, for its outline and shadow when the screen's content changes.
    func silhouette(of device: DeviceInfo) async throws -> DeviceRender {
        let size = device.inputSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let solid = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        return try await deviceRender(id: Self.silhouetteID, screenshot: solid, device: device)
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

    /// Wraps a value Core Image hands between threads safely but doesn't declare as `Sendable`.
    private struct Unchecked<Value>: @unchecked Sendable {
        let value: Value

        init(_ value: Value) {
            self.value = value
        }
    }

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

    /// The frame's art, drawn once into a buffer that stays on the GPU.
    private func frameImage(for device: DeviceInfo) async throws -> CIImage {
        let layer = try await layers.layer(for: "frame|\(device.deviceFrame)") { [self] in
            guard let cgImage = device.frameImage?.cgImage else { throw LayerStoreError.missingFrame }

            let image = CIImage(cgImage: cgImage)

            return CachedLayer(image: try bake(image, extent: image.extent), cost: bytes(of: image.extent))
        }

        return layer.image
    }

    /// The screenshot scaled to the screen, clipped to its rounded corners, and placed where the frame has its screen.
    private func screenLayer(id: UUID, screenshot: UIImage, device: DeviceInfo) async throws -> CIImage {
        let layer = try await layers.layer(for: "screen|\(screenKey(id: id, device: device))") { [self] in
            let frame = try await frameImage(for: device)

            guard let source = CIImage(image: screenshot) else { throw LayerStoreError.bufferFailed }

            let screen = placedScreen(source, device: device, frameSize: frame.extent.size)
            let baked = try bake(screen.cropped(to: frame.extent), extent: frame.extent)

            return CachedLayer(image: baked, cost: bytes(of: frame.extent))
        }

        return layer.image
    }

    /// Scales a picture to the device's screen, clips it to the screen's corners, and puts it where the frame has its screen.
    private func placedScreen(_ source: CIImage, device: DeviceInfo, frameSize: CGSize) -> CIImage {
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
        return screen.transformed(by: CGAffineTransform(
            translationX: device.offSet.x,
            y: frameSize.height - device.offSet.y - device.screenSize.height
        ))
    }

    /// Folds a flat device. The fold draws its own shadow, on a canvas larger than the device.
    private func foldedRender(of flat: CIImage, openingAngle: Double) throws -> CIImage {
        guard
            let cgImage = context.createCGImage(flat, from: flat.extent),
            let folded = UIImage(cgImage: cgImage).partiallyOpened(openingAngle: openingAngle),
            let foldedCI = CIImage(image: folded)
        else {
            throw LayerStoreError.bufferFailed
        }

        return try bake(foldedCI, extent: foldedCI.extent)
    }

    /// A soft shadow below a device. Its shape comes from the device's outline, which every color of the device shares, so
    /// it is drawn once per outline and not again when the color changes.
    ///
    /// The shadow is kept as a single gray channel, one quarter of the memory of a color image, and turned into a black
    /// image with transparency when it is used.
    private func shadow(for device: DeviceInfo) async throws -> CIImage {
        let outline = device.colors.first.map(device.withColor) ?? device
        let key = "shadow|\(outline.deviceFrame)|\(outline.offSet.x)|\(outline.offSet.y)"

        let layer = try await layers.layer(for: key) { [self] in
            let frame = try await frameImage(for: outline)
            let solid = CIImage(color: .black).cropped(to: CGRect(origin: .zero, size: outline.screenSize))
            let flat = frame
                .composited(over: placedScreen(solid, device: outline, frameSize: frame.extent.size))
                .cropped(to: frame.extent)

            let extent = shadowExtent(of: flat)

            return CachedLayer(image: try bakeMask(shadowMask(of: flat), extent: extent), cost: Int(extent.width * extent.height))
        }

        // The gray becomes the shadow's transparency, with no color of its own.
        return layer.image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: Self.shadowOpacity, y: 0, z: 0, w: 0)
        ])
    }

    /// A blurred, offset copy of a device's outline as gray, white where the shadow is darkest.
    private func shadowMask(of device: CIImage) -> CIImage {
        let extent = device.extent

        return device
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 1)
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

    /// Like `bake`, for a gray picture, using one byte per pixel.
    private func bakeMask(_ image: CIImage, extent: CGRect) throws -> CIImage {
        let width = Int(extent.width.rounded(.up))
        let height = Int(extent.height.rounded(.up))
        var buffer: CVPixelBuffer?

        CVPixelBufferCreate(
            nil,
            width,
            height,
            kCVPixelFormatType_OneComponent8,
            [
                kCVPixelBufferIOSurfacePropertiesKey: [:],
                kCVPixelBufferMetalCompatibilityKey: true
            ] as CFDictionary,
            &buffer
        )

        guard let buffer else { throw LayerStoreError.bufferFailed }

        context.render(image, to: buffer, bounds: extent, colorSpace: linearGray)

        return CIImage(cvPixelBuffer: buffer, options: [.colorSpace: linearGray])
            .transformed(by: CGAffineTransform(translationX: extent.minX, y: extent.minY))
    }

    private func bytes(of extent: CGRect) -> Int {
        Int(extent.width * extent.height) * 4
    }
}
