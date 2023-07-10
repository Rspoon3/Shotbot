//
//  PurchaseManager.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/4/23.
//

import Foundation
import RevenueCat
import Persistence
import OSLog
import Models

public final class PurchaseManager: NSObject, ObservableObject, PurchaseManaging, PurchasesDelegate {
    public static let shared = PurchaseManager()
    private let purchases = Purchases.shared
    private let persistenceManager = PersistenceManager.shared
    private let logger = Logger(category: PurchaseManager.self)

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
        do {
            offerings = try await purchases.offerings()
            logger.info("Fetched offers.")
        } catch {
            logger.error("Error fetching offers: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    @MainActor
    public func restorePurchases() async throws {
        do {
            customerInfo = try await purchases.restorePurchases()
            logger.info("Restored purchases.")
        } catch {
            logger.error("Error restoring purchases: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    @MainActor
    public func purchase(_ package: Package) async throws {
        logger.info("Purchase: \(package.storeProduct.description, privacy: .public).")
        
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


//#if DEBUG
public class MockPurchaseManager: ObservableObject, PurchaseManaging {
    public var offerings: RevenueCat.Offerings?
    public var paymentIsInProgress: Bool = false
    
    public var didRestorePurchases = false
    public func restorePurchases() async throws {
        didRestorePurchases = true
    }
    
    public var purchaseResult: Result<Void, Error>?
    public func purchase(_ package: Package) async throws {
        _ = try purchaseResult?.get()
    }
    
    
    public init() {}
}
//#endif
