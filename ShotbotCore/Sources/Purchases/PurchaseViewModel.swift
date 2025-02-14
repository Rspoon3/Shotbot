//
//  PurchaseViewModel.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/8/23.
//

import Foundation
import RevenueCat
import Persistence
import Models
import OSLog
import SwiftTools

@MainActor final class PurchaseViewModel: ObservableObject {
    private let purchaseManager: PurchaseManaging
    private let persistenceManager = PersistenceManager.shared
    private let logger = Logger(category: PurchaseViewModel.self)

    @Published private(set) var userAction: UserAction?
    @Published var error: Error?
    
    enum UserAction {
        case purchasing
        case restoring
    }
    
    init(purchaseManager: PurchaseManaging = PurchaseManager.shared) {
        self.purchaseManager = purchaseManager
    }
    
    private var annualPackage: Package? {
        purchaseManager.offerings?.current?.annual
    }
    
    var annulPriceText: String {
        guard
            let product = annualPackage?.storeProduct,
            let subscriptionPeriod = product.subscriptionPeriod?.unit,
            let trailPeriod = product.introductoryDiscount?.subscriptionPeriod
        else {
            return "Pricing unavailable"
        }
        
        return "\(trailPeriod.value) \(trailPeriod.unit) free trial, then \(product.localizedPriceString)/\(subscriptionPeriod)"
    }
    
    var buttonDisabled: Bool {
        purchaseManager.paymentIsInProgress || persistenceManager.isSubscribed || userAction != nil
    }
    
    var isSubscribed: Bool {
        persistenceManager.isSubscribed
    }
    
    // MARK: - Public Helpers
    
    func restorePurchase() {
        userAction = .restoring
        
        Task {
            defer { userAction = nil }
            
            do {
                try await purchaseManager.restorePurchases()
            } catch {
                self.error = error
            }
        }
    }
    
    func purchase() {
        guard let annualPackage else {
            logger.error("No annual package to purchase.")
            self.error = SBError.noAnnualPackage
            return
        }
        
        Task {
            userAction = .purchasing
            
            do {
                defer { userAction = nil }

                try await purchaseManager.purchase(annualPackage)
            } catch {
                self.error = error
            }
        }
    }
}
