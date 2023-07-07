//
//  SettingsView.swift
//  Shot Bot
//
//  Created by Richard Witherspoon on 4/20/23.
//

import SwiftUI
import Persistence
import MessageUI
import Models
import Purchases
import OSLog

public struct SettingsView: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var persistenceManager: PersistenceManager
    @State private var showEmail = false
    @State private var showEmailAlert = false
    @State private var showEmailFailedAlert = false
//    @State private var attachments: [MailView.Attachment]?
    private let appID = 6450552843
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Body
    
    private func createFeedbackMessage() -> MailView.Message{
        let systemVersion = UIDevice.current.systemVersion
        var message = "\n\n\n\n\n\n\n\n\n\nOS Version: \(systemVersion)"
        
        if let version = Bundle.appVersion, let build = Bundle.appBuild {
            message.append("\nApp Version: \(version) (\(build))")
        }
        
        return .init(message: message, isHTML: false)
    }
    
//    func export() {
//        do {
//            let store = try OSLogStore(scope: .currentProcessIdentifier)
//            let position = store.position(timeIntervalSinceLatestBoot: 1)
//            let entries = try store
//                .getEntries(at: position)
//                .compactMap { $0 as? OSLogEntryLog }
//                .filter { $0.subsystem == Bundle.main.bundleIdentifier! }
//                .map { "[\($0.date.formatted())] [\($0.category)] [\($0.level.rawValue)] \($0.composedMessage)" }
//
//            let joined = entries.joined(separator: "\n")
//            let data = joined.data(using: .utf8)!
//
//            attachments = [MailView.Attachment(data: data, mimeType: "text/plain", fileName: "logs.txt")]
//            showEmail = true
//        } catch {
//
//        }
//    }
    
    public var body: some View {
        Form {
            Section("App Settings") {
                Toggle("Automatically save to files", isOn: $persistenceManager.autoSaveToFiles)
                Toggle("Automatically save to photos", isOn: $persistenceManager.autoSaveToPhotos)
                Toggle("Automatically delete screenshots", isOn: $persistenceManager.autoDeleteScreenshots)
                Toggle("Clear Images On App Background", isOn: $persistenceManager.clearImagesOnAppBackground)
            }
            
            Section() {
                Picker("Image Selection Filter", selection: $persistenceManager.imageSelectionType) {
                    ForEach(ImageSelectionType.allCases) { type in
                        Text(type.title)
                            .tag(type)
                    }
                }
                Picker("Image Quality", selection: $persistenceManager.imageQuality) {
                    ForEach(ImageQuality.allCases) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
            }
            
            Section("Feedback") {
                Button {
                    openURL(.mastodon)
                } label: {
                    Label("Mastodon", systemImage: "link")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                
                Button {
                    openURL(.twitter(username: "Rspoon3"))
                } label: {
                    Label("Twitter", systemImage: "link")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                
                Button {
                    if MFMailComposeViewController.canSendMail() {
                        showEmail = true
                    } else {
                        showEmailAlert = true
                    }
                } label: {
                    Label("Email Feedback", systemImage: "envelope")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .alert(isPresented: $showEmailAlert) {
                    Alert(
                        title: Text("Email Error"),
                        message: Text("Email services are not available on this device")
                    )
                }
                .alert(isPresented: $showEmailFailedAlert) {
                    Alert(
                        title: Text("Email Error"),
                        message: Text("An error occurred sending your email")
                    )
                }
                .sheet(isPresented: $showEmail) {
                    MailView(
                        recipients: ["richardwitherspoon3@gmail.com"],
                        subject: "Shot Bot Feedback",
                        message: createFeedbackMessage(),
                        attachments: nil) { result in
                            if case .failure = result {
                                showEmailFailedAlert = true
                            }
                        }
                }
                
                Button {
                    openURL(.appStore(appID: appID))
                } label: {
                    Label("Leave a review", systemImage: "star")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
            }
            
            Section("Other") {
                NavigationLink {
                    PurchaseView()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Shotbot Pro")
                            if !persistenceManager.isSubscribed {
                                Text("\(persistenceManager.freeFramedScreenshotsRemaining) free screenshots remaining")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    } icon: {
                        Image(systemName: "heart")
                    }
                }
                
                NavigationLink {
                    SupportedDevicesView()
                } label: {
                    Label("Supported Devices", systemImage: "macbook.and.iphone")
                }
                
                NavigationLink {
                    AppPermissionsView()
                } label: {
                    Label("App Permissions", systemImage: "lock.shield")
                }
                
                Button {
                    openURL(.gitHub)
                } label: {
                    Label("Source Code", systemImage: "doc.plaintext")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                
                Button {
                    openURL(.privacyPolicy)
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                
                Button {
                    openURL(.termsAndConditions)
                } label: {
                    Label("Terms & Conditions", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
            }
            
#if DEBUG
            Section("Debug") {
                Text("Number of launches")
                    .badge(persistenceManager.numberOfLaunches)
                Text("Number of activations")
                    .badge(persistenceManager.numberOfActivations)
                Text("Number of device frame creations")
                    .badge(persistenceManager.deviceFrameCreations)
                Text("Is Subscribed")
                    .badge(persistenceManager.isSubscribed.description)
                
                Picker("Subscription Override", selection: $persistenceManager.subscriptionOverride) {
                    ForEach(PersistenceManager.SubscriptionOverrideMethod.allCases) { type in
                        Text(type.id)
                            .tag(type)
                    }
                }
            }
#endif
            
            SettingsMadeBy(appID: appID)
        }
        .navigationTitle("Settings")
        .buttonStyle(.plain)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(PersistenceManager.shared)
        }
    }
}
