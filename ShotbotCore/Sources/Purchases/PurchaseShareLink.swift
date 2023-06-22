//
//  PurchaseShareLink.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/6/23.
//

import SwiftUI
import Persistence

public struct PurchaseShareLink<Data: RandomAccessCollection>: View where Data.Element == URL {
    @EnvironmentObject private var persistenceManager: PersistenceManager
    let items: Data
    @Binding var showPurchaseView: Bool
    
    public init(items: Data, showPurchaseView: Binding<Bool>) {
        self.items = items
        _showPurchaseView = showPurchaseView
    }
    
    public var body: some View {
        Group {
            if persistenceManager.canSaveFramedScreenshot {
                ShareLink(items: items)
            } else {
                Button {
                    showPurchaseView = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .id(UUID())
    }
}

struct PurchaseShareLink_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseShareLink(items: [], showPurchaseView: .constant(true))
            .environmentObject(PersistenceManager.shared)
    }
}
