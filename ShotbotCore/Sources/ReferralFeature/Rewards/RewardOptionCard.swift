//
//  RewardOptionCard.swift
//  Shotbot
//

import SwiftUI
import ReferralService

struct RewardOptionCard: View {
    let option: AvailablePurchase
    let isSelected: Bool
    let canAfford: Bool
    let onTap: () -> Void
    
    private func creditText(for amount: Int) -> String {
        amount == 1 ? "credit" : "credits"
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option.symbolString)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let cost = option.cost
                    Text(cost.formatted())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(canAfford ? .blue : .secondary)
                    
                    Text(creditText(for: cost))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canAfford)
        .opacity(canAfford ? 1.0 : 0.6)
    }
}