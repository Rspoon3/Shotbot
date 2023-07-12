//
//  SettingsViewModel.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 7/7/23.
//

import UIKit
import OSLog
import Models
import MessageUI

@MainActor class SettingsViewModel: ObservableObject {
    let appID = 6450552843
    private let logger = Logger(category: SettingsView.self)
    @Published private(set) var isGeneratingLogs = false
    @Published var showEmail = false
    @Published var showEmailAlert = false
    @Published var showEmailFailedAlert = false
    @Published private(set) var attachments: [MailView.Attachment]?
    
    var emailButtonText: String {
        isGeneratingLogs ? "Generating Logs..." : "Email Feedback"
    }
    
    
    // MARK: - Public
    
    func createFeedbackMessage() -> MailView.Message{
        let systemVersion = UIDevice.current.systemVersion
        var message = "\n\n\n\n\n\n\n\n\n\nOS Version: \(systemVersion)"
        
        if let version = Bundle.appVersion, let build = Bundle.appBuild {
            message.append("\nApp Version: \(version) (\(build))")
        }
        
        return .init(message: message, isHTML: false)
    }
    
    func emailFeedbackButtonTapped() {
        if MFMailComposeViewController.canSendMail() {
            logger.info("Generating logs.")
            
            Task(priority: .userInitiated) {
                isGeneratingLogs = true
                try? await generateLogAttachments()
                isGeneratingLogs = false
                showEmail = true
                logger.info("Showing email sheet for feedback.")
            }
        } else {
            showEmailAlert = true
            logger.error("Email is not supported on this device.")
        }
    }
    
    // MARK: - Private
    
    nonisolated private func generateLogAttachments() async throws {
        try await Task {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let twoHoursAgo = store.position(date: Date.now.subtracting(hours: 2))
            
            let entries = try store
                .getEntries(at: twoHoursAgo)
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == Logger.subsystem }
                .map { "[\($0.date.formatted())] [\($0.category)] [\($0.level.rawValue)] \($0.composedMessage)" }
            
            let joined = entries.joined(separator: "\n")
            
            guard let data = joined.data(using: .utf8) else {
                return
            }
            
            await MainActor.run {
                attachments = [
                    MailView.Attachment(
                        data: data, mimeType: "text/plain",
                        fileName: "logs.txt"
                    )
                ]
            }
        }.value
    }
}
