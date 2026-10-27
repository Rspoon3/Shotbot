//
//  CachedLayer.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage

/// An image held by the `LayerCache`, with its size in memory so the cache can stay within its budget.
struct CachedLayer: @unchecked Sendable {
    let image: CIImage
    /// The memory the layer uses, in bytes.
    let cost: Int

    init(image: CIImage, cost: Int) {
        self.image = image
        self.cost = cost
    }
}
