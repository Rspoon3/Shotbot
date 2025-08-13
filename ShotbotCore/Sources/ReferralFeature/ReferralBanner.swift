//
//  ReferralBanner.swift
//  Shotbot
//

import SwiftUI
import Persistence

public struct ReferralBanner: View {
    @State private var scale: Double = 1
    @State private var showingReferralView = false
    @EnvironmentObject private var persistenceManager: PersistenceManager
    
    public init() {}
    
    public var body: some View {
        Button {
            showingReferralView = true
        } label: {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    
                    Image(systemName: "gift.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Text("Refer & Earn!")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Share Shotbot with friends to unlock extra screenshots and custom codes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(scale)
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: scale)
        .task {
            try? await Task.sleep(for: .seconds(1))
            scale = 0.97
        }
        .sheet(isPresented: $showingReferralView) {
            NavigationStack {
                ReferralView()
                    .environmentObject(persistenceManager)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") {
                                showingReferralView = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    ReferralBanner()
        .padding()
}
