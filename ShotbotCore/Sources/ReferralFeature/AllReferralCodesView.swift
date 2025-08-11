//
//  AllReferralCodesView.swift
//  Shotbot
//

import SwiftUI
import ReferralService

struct AllReferralCodesView: View {
    @EnvironmentObject private var viewModel: ReferralViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.referralCodes, id: \.id) { code in
                    ReferralCodeCard(code: code)
                }
            }
            .padding()
        }
        .navigationTitle("All Referral Codes")
        .navigationBarTitleDisplayMode(.inline)
    }
}