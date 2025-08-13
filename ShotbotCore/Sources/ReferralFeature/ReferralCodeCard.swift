//
//  ReferralCodeCard.swift
//  Shotbot
//

import SwiftUI
import ReferralService

/// Card view for displaying a referral code with share functionality
struct ReferralCodeCard: View {
    @State private var showCheckmark = false
    let code: ReferralCode
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(code.code)
                    .font(.title)
                    .fontWeight(.bold)
                    .fontDesign(.monospaced)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = code.code
                    feedbackGenerator.notificationOccurred(.success)
                    showCheckmark = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        showCheckmark = false
                    }
                } label: {
                    Image(symbol: showCheckmark ? .checkmark : .docOnDoc)
                        .foregroundColor(.blue)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(widthAndHeight: 44)
                .disabled(showCheckmark)
            }
            
            Text(code.type.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            ShareLink(item: "Turn your screenshots into beautiful screenshots! Use my code \(code.code) for Shotbot: \(URL.appStore(appID: 6450552843))") {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Code")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

#if DEBUG
#Preview {
    ReferralCodeCard(code: .mock)
        .padding()
}
#endif
