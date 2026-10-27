//
//  CachedLayer.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage

/// An image, and optionally its shadow, held by the `LayerCache`, with its size in memory so the cache can stay within
/// its budget.
struct CachedLayer: @unchecked Sendable {
    let image: CIImage
    let shadow: CIImage?
    /// The memory the layer uses, in bytes.
    let cost: Int

    init(image: CIImage, shadow: CIImage? = nil, cost: Int) {
        self.image = image
        self.shadow = shadow
        self.cost = cost
    }
}
