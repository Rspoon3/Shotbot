//
//  MetalImageView.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage
import MetalKit
import SwiftUI

/// Draws a Core Image picture straight onto the GPU, scaled to fit, without making a bitmap first.
struct MetalImageView: UIViewRepresentable {
    /// The picture to show. Its extent should start at the origin.
    let image: CIImage

    func makeUIView(context: Context) -> CIMetalView {
        CIMetalView()
    }

    func updateUIView(_ view: CIMetalView, context: Context) {
        view.image = image
    }

    /// A Metal view that renders a Core Image picture whenever the picture or the view's size changes.
    final class CIMetalView: MTKView {
        /// The picture to draw. Setting it draws it on the next screen update.
        var image: CIImage? {
            didSet { setNeedsDisplay() }
        }

        /// Whether to draw colors brighter than white, for HDR video. Standard pictures use the cheaper 8-bit surface.
        var isHDR = false {
            didSet {
                guard isHDR != oldValue else { return }

                colorPixelFormat = isHDR ? .rgba16Float : .bgra8Unorm

                if let metalLayer = layer as? CAMetalLayer {
                    metalLayer.wantsExtendedDynamicRangeContent = isHDR
                    metalLayer.colorspace = isHDR ? CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3) : nil
                }

                setNeedsDisplay()
            }
        }

        private let store = LayerStore.shared

        init() {
            super.init(frame: .zero, device: LayerStore.shared.metalDevice)

            isOpaque = false
            backgroundColor = .clear
            clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            framebufferOnly = false
            isPaused = true
            enableSetNeedsDisplay = true
            colorPixelFormat = .bgra8Unorm
            autoResizeDrawable = true
        }

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            setNeedsDisplay()
        }

        override func draw(_ rect: CGRect) {
            guard
                let image,
                image.extent.width > 0,
                image.extent.height > 0,
                let drawable = currentDrawable,
                let buffer = store.commandQueue?.makeCommandBuffer()
            else {
                return
            }

            let target = drawableSize
            let scale = min(target.width / image.extent.width, target.height / image.extent.height)
            let width = image.extent.width * scale
            let height = image.extent.height * scale
            let bounds = CGRect(origin: .zero, size: target)

            let fitted = image
                .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                .transformed(by: CGAffineTransform(translationX: (target.width - width) / 2, y: (target.height - height) / 2))
                .composited(over: CIImage(color: .clear).cropped(to: bounds))

            let destination = CIRenderDestination(
                width: Int(target.width),
                height: Int(target.height),
                pixelFormat: colorPixelFormat,
                commandBuffer: buffer
            ) { drawable.texture }

            destination.isFlipped = true
            destination.colorSpace = CGColorSpace(name: isHDR ? CGColorSpace.extendedLinearDisplayP3 : CGColorSpace.displayP3)

            _ = try? store.context.startTask(toRender: fitted, from: bounds, to: destination, at: .zero)

            buffer.present(drawable)
            buffer.commit()
        }
    }
}
