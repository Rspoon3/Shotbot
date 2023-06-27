//
//  PurchaseManager.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/4/23.
//

import Foundation
import RevenueCat
import Persistence

public final class PurchaseManager: NSObject, ObservableObject, PurchaseManaging, PurchasesDelegate {
    public static let shared = PurchaseManager()
    private let purchases = Purchases.shared
    private let persistenceManager = PersistenceManager.shared
    
    @Published public var offerings: Offerings? = nil
    @Published public var paymentIsInProgress = false
    @Published var customerInfo: CustomerInfo? {
        didSet {
            Task {
                await MainActor.run {
                    let pro = customerInfo?.entitlements["Pro"]
                    persistenceManager.isSubscribed = pro?.isActive == true
                }
            }
        }
    }
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        purchases.delegate = self
    }
    
    // MARK: - PurchaseManaging
    @MainActor
    public func fetchOfferings() async {
        offerings = try? await purchases.offerings()
    }
    
    @MainActor
    public func restorePurchases() async throws {
        customerInfo = try await purchases.restorePurchases()
    }
    
    @MainActor
    public func purchase(_ package: Package) async throws {
        purchases.attribution.setAttributes(["numberOfLaunches": "\(persistenceManager.numberOfLaunches)"])
        purchases.attribution.setAttributes(["numberOfActivations": "\(persistenceManager.numberOfActivations)"])
        purchases.attribution.setAttributes(["deviceFrameCreations": "\(persistenceManager.deviceFrameCreations)"])
        
        let data = try await purchases.purchase(package: package)
        customerInfo = data.customerInfo
    }
    
    // MARK: - PurchasesDelegate
   
    public func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task {
            await MainActor.run {
                self.customerInfo = customerInfo
            }
        }
    }
    
    public func purchases(
        _ purchases: Purchases,
        readyForPromotedProduct product: StoreProduct,
        purchase startPurchase: @escaping StartPurchaseBlock
    ) {
        paymentIsInProgress = false
        startPurchase { [weak self] transaction, info, error, cancelled in
            guard
                let self,
                let info,
                error == nil,
                !cancelled
            else {
                return
            }
            
            DispatchQueue.main.async {
                self.customerInfo = info
            }
        }
    }
}
