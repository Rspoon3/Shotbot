//
//  PurchaseViewModel.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/8/23.
//

import Foundation
import RevenueCat
import Persistence

@MainActor final class PurchaseViewModel: ObservableObject {
    private let purchaseManager = PurchaseManager.shared
    private let persistenceManager = PersistenceManager.shared
    @Published private(set) var userAction: UserAction?
    @Published var showAlert = false

    enum UserAction {
        case purchasing
        case restoring
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
        defer { userAction = nil }
        
        Task {
            do {
                try await purchaseManager.restorePurchases()
            } catch {
                showAlert = true
            }
        }
    }
    
    func purchase() {
        guard let annualPackage else {
            showAlert = true
            return
        }
        
        Task {
            userAction = .purchasing
            defer { userAction = nil }
            
            do {
                try await purchaseManager.purchase(annualPackage)
            } catch {
                showAlert = true
            }
        }
    }
}
