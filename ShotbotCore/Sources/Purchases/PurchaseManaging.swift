//
//  PurchaseManaging.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/21/23.
//

import Foundation
import RevenueCat

public protocol PurchaseManaging {
    func restorePurchases() async throws
    func purchase(_ package: Package) async throws
}
