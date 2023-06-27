//
//  File.swift
//  
//
//  Created by Richard Witherspoon on 6/21/23.
//

import Foundation
import Purchases
import RevenueCat


class MockPurchaseManager: PurchaseManaging {
    var didRestorePurchases = false
    func restorePurchases() async throws {
        didRestorePurchases = true
    }
    
    var purchaseResult: Result<Void, Error>?
    func purchase(_ package: Package) async throws {
        _ = try purchaseResult?.get()
    }
}
