//
//  PHFetchResult+PHAssets.swift
//
//
//  Created by Richard Witherspoon on 7/22/24.
//

import Foundation
import Photos

extension PHFetchResult<PHAsset> {
    var phAssets: [PHAsset] {
        self.objects(at: IndexSet(0 ..< self.count))
    }
}
