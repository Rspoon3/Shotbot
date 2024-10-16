//
//  PurchaseManaging.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/21/23.
//

import Foundation
import RevenueCat

@MainActor
public protocol PurchaseManaging {
    var offerings: Offerings? { get }
    var paymentIsInProgress: Bool { get set }
    func restorePurchases() async throws
    func purchase(_ package: Package) async throws
}
