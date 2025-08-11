//
//  ReferralCodeCard.swift
//  Shotbot
//

import SwiftUI
import ReferralService

struct ReferralCodeCard: View {
    let code: ReferralCode
    @State private var isCopied = false
    @EnvironmentObject private var viewModel: ReferralViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(code.code)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if code.isCustom {
                        Label("Custom Code", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        copyCode()
                    } label: {
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundColor(isCopied ? .green : .blue)
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        viewModel.shareReferralCode()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if code.usageCount > 0 {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(code.usageCount) \(code.usageCount == 1 ? "friend" : "friends") joined")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .sheet(isPresented: $viewModel.showingShareSheet) {
            ShareSheet(items: viewModel.createShareContent())
        }
    }
    
    private func copyCode() {
        UIPasteboard.general.string = code.code
        withAnimation(.easeInOut(duration: 0.2)) {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopied = false
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}