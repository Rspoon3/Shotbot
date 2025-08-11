//
//  ReferralCodeInputView.swift
//  Shotbot
//

import SwiftUI

struct ReferralCodeInputView: View {
    @EnvironmentObject private var viewModel: ReferralViewModel
    @EnvironmentObject private var persistenceManager: PersistenceManager
    @Environment(\.dismiss) private var dismiss
    @State private var codeInput = ""
    @State private var isValidating = false
    @FocusState private var isInputFocused: Bool
    
    private var validationResult: ReferralCodeValidator.ValidationResult {
        viewModel.codeValidator.validate(codeInput)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection
                
                inputSection
                
                Spacer()
                
                actionButtons
            }
            .padding()
            .navigationTitle("Enter Referral Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Have a referral code?")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Enter your friend's code to get started with bonus features")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Enter code", text: $codeInput)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isInputFocused)
                .font(.title3)
                .multilineTextAlignment(.center)
            
            if !codeInput.isEmpty && !validationResult.isValid {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text(validationResult.message ?? "Invalid code")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .transition(.opacity)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await useCode()
                }
            } label: {
                HStack {
                    if isValidating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle")
                    }
                    Text("Use Code")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(maxWidth: 300)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!validationResult.isValid || isValidating || codeInput.isEmpty)
            
            Button("I don't have a code") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
    }
    
    private func useCode() async {
        guard validationResult.isValid else { return }
        
        isValidating = true
        defer { isValidating = false }
        
        let newBalance = await viewModel.useReferralCode(codeInput)
        
        if let balance = newBalance {
            persistenceManager.creditBalance = balance
            persistenceManager.canEnterReferralCode = false
            viewModel.successMessage = "Code applied successfully! You now have \(balance) \(balance == 1 ? "credit" : "credits")"
            viewModel.showingSuccessMessage = true
            dismiss()
        } else if let error = viewModel.error {
            viewModel.showingError = true
        }
    }
}