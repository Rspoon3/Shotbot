//
//  ReferralCodeInputView.swift
//  Shotbot
//

import SwiftUI
import Persistence

struct ReferralCodeInputView: View {
    @ObservedObject var viewModel: ReferralViewModel
    @EnvironmentObject private var persistenceManager: PersistenceManager
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage: String?
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Enter Referral Code")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter the referral code from a friend")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    ValidatedTextFieldComponent(
                        text: $inputText,
                        placeholder: "ABC123",
                        validator: viewModel.codeValidator
                    )
                }
                
                Button {
                    Task {
                        if let newCreditBalance = await viewModel.useReferralCode(inputText) {
                            persistenceManager.canEnterReferralCode = false
                            persistenceManager.creditBalance = newCreditBalance
                            showingSuccessAlert = true
                            feedbackGenerator.notificationOccurred(.success)
                        } else if viewModel.error != nil {
                            feedbackGenerator.notificationOccurred(.error)
                            errorMessage = "The referral code you entered is not valid. Please check the code and try again."
                            showingErrorAlert = true
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isUsingCode {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        
                        Text(viewModel.isUsingCode ? "Using Code..." : "Use Code")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxWidth: 300)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.codeValidator.shouldDisableSubmit(for: inputText, isLoading: viewModel.isUsingCode))
                
                Spacer()
            }
            .padding()
            .navigationTitle("Use Referral Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("You've successfully used the referral code \(inputText.uppercased())!")
            }
            .alert("Code Error", isPresented: $showingErrorAlert) {
                Button("Cancel", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                Text(errorMessage ?? "An error occurred.")
            }
        }
    }
}

struct ValidatedTextFieldComponent: View {
    @Binding var text: String
    let placeholder: String
    let validator: ReferralCodeValidator
    
    @State private var hasValidCharacters = true
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .font(.title2)
            .foregroundStyle(hasValidCharacters ? Color.primary : Color.red)
            .fontDesign(.monospaced)
            .textCase(.uppercase)
            .autocorrectionDisabled()
            .focused($isFocused)
            .onChange(of: text) { _, newValue in
                handleInputChange(of: newValue)
            }
            .onAppear {
                isFocused = true
            }
    }
    
    private func handleInputChange(of newValue: String) {
        hasValidCharacters = validator.hasValidCharacters(newValue)
        
        let uppercased = newValue.uppercased()
        
        if let maxLength = validator.maxLength {
            text = String(uppercased.prefix(maxLength))
        } else {
            text = uppercased
        }
    }
}