//
//  AllReferralCodesView.swift
//  Shotbot
//

import SwiftUI
import ReferralService

struct AllReferralCodesView: View {
    @ObservedObject var viewModel: ReferralViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.referralCodes, id: \.id) { code in
                    ReferralCodeCard(code: code, viewModel: viewModel)
                }
            }
            .padding()
        }
        .navigationTitle("All Referral Codes")
        .navigationBarTitleDisplayMode(.inline)
    }
}