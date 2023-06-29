//
//  View+Extension.swift
//  
//
//  Created by Richard Witherspoon on 6/29/23.
//

import SwiftUI

extension View {
    public func alert(
        error: Binding<Error?>,
        buttonTitle: String = "OK"
    ) -> some View {
        alert(
            error.wrappedValue?.localizedDescription ?? "Error",
            isPresented: .constant(error.wrappedValue != nil)
        ) {
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: {
            if let localizedError = error.wrappedValue as? LocalizedError,
               let recoverySuggestion = localizedError.recoverySuggestion {
                Text(recoverySuggestion)
            } else {
                Text("")
            }
        }
    }
}
