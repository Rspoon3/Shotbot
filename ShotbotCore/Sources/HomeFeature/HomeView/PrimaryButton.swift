//
//  PrimaryButton.swift
//  ShotbotCore
//
//  Created by Ricky on 9/26/24.
//
import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label:{
            Text(title)
                .font(.headline)
                .frame(maxWidth: 300)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}
