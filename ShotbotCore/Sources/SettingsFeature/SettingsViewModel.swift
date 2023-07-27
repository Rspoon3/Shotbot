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
import SBFoundation

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
        guard MFMailComposeViewController.canSendMail() else {
            showEmailAlert = true
            logger.error("Email is not supported on this device.")
            return
        }
        
        logger.info("Generating logs.")
        
        Task(priority: .userInitiated) {
            isGeneratingLogs = true
            
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let twoHoursAgo = Date.now.subtracting(hours: 2)
            let logs = try await store.generateLogAttachments(startDate: twoHoursAgo)
            
            try createCSVFile(from: logs)
            isGeneratingLogs = false
            showEmail = true
            logger.info("Showing email sheet for feedback.")
        }
    }
    
    private func createCSVFile(from logs: [SBLog]) throws {
        let logMessages = logs.map(\.text).joined(separator: "\n")
        let stringValue = "Date, Time, Category, Level, Message"
            .appending("\n")
            .appending(logMessages)
        
        guard let data = stringValue.data(using: .utf8) else {
            throw SBError.noData
        }

        attachments = [
            MailView.Attachment(
                data: data, mimeType: "csv",
                fileName: "DebugLog.csv"
            )
        ]
    }
}
