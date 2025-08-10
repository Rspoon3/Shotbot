//
//  SettingsView.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/20/23.
//

import SwiftUI
import Persistence
import Models
import Purchases
import SwiftTools

public struct SettingsView: View {
    let appID = 6450552843
    @State private var logExporter = LogExporter()
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var persistenceManager: PersistenceManager
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        Form {
            Section {
                Toggle("Automatically save to files", isOn: $persistenceManager.autoSaveToFiles)
                Toggle("Automatically save to photos", isOn: $persistenceManager.autoSaveToPhotos)
                Toggle("Automatically copy", isOn: $persistenceManager.autoCopy)
                Toggle("Automatically delete screenshots", isOn: $persistenceManager.autoDeleteScreenshots)
                Toggle("Clear images on app background", isOn: $persistenceManager.clearImagesOnAppBackground)
            } header: {
                Text("App Settings")
#if os(visionOS)
                    .padding(.top, 40)
#endif
            }
            Section() {
                Picker("Default Home Tab", selection: $persistenceManager.defaultHomeTab) {
                    ForEach(ImageType.allCases) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }

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
                    openURL(.personalMastodon)
                } label: {
                    Label("Mastodon", symbol: .link)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }

                Button {
                    openURL(.twitter(username: "Rspoon3"))
                } label: {
                    Label("Twitter", symbol: .link)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }

                Button {
                    Task {
                        try? await logExporter.emailFeedbackButtonTapped()
                    }
                } label: {
                    Label {
                        Text(logExporter.emailButtonText)
                    } icon: {
                        if logExporter.isGeneratingLogs {
                            ProgressView()
                        } else {
                            Image(symbol: .envelope)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .animation(.default, value: logExporter.isGeneratingLogs)
                .disabled(logExporter.isGeneratingLogs)
                .alert(isPresented: $logExporter.showEmailAlert) {
                    Alert(
                        title: Text("Email Error"),
                        message: Text("Email services are not available on this device")
                    )
                }
                .sheet(isPresented: $logExporter.showEmail) {
                    MailView(
                        recipients: logExporter.recipients,
                        subject: "Shotbot Feedback",
                        message: logExporter.createFeedbackMessage(),
                        attachments: logExporter.attachments
                    ) { result in
                        if case .failure = result {
                            logExporter.showEmailAlert = true
                        }
                    }
                }

                Button {
                    openURL(.appStore(appID: appID))
                } label: {
                    Label("Leave a review", symbol: .star)
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
                        Image(symbol: .heart)
                    }
                }

                NavigationLink {
                    SupportedDevicesView()
                } label: {
                    Label("Supported Devices", symbol: .macbookAndIphone)
                }

                NavigationLink {
                    AppPermissionsView()
                } label: {
                    Label("App Permissions", symbol: .lockShield)
                }

                Button {
                    openURL(.gitHub)
                } label: {
                    Label("Source Code", symbol: .docPlaintext)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }

                Button {
                    openURL(.privacyPolicy)
                } label: {
                    Label("Privacy Policy", symbol: .handRaised)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }

                Button {
                    openURL(.termsAndConditions)
                } label: {
                    Label("Terms & Conditions", symbol: .exclamationmarkTriangle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
            }

#if DEBUG
            Section("Debug") {
                LabeledContent(
                    "Number of launches",
                    value: persistenceManager.numberOfLaunches,
                    format: .number
                )
                
                LabeledContent(
                    "Number of activations",
                    value: persistenceManager.numberOfActivations,
                    format: .number
                )
                
                LabeledContent(
                    "Number of device frame creations",
                    value: persistenceManager.deviceFrameCreations,
                    format: .number
                )
                
                LabeledContent(
                    "Is Subscribed",
                    value: persistenceManager.isSubscribed.description
                )

                Picker("Subscription Override", selection: $persistenceManager.subscriptionOverride) {
                    ForEach(PersistenceManager.SubscriptionOverrideMethod.allCases) { type in
                        Text(type.id)
                            .tag(type)
                    }
                }
                
                NavigationLink {
                    SwiftDataDebugView()
                } label: {
                    Label("SwiftData Debug", systemImage: "externaldrive.connected.to.line.below")
                }
                
                NavigationLink {
                    SwiftDataModelDebugView()
                } label: {
                    Label("SwiftData DebugV2", systemImage: "externaldrive.connected.to.line.below")
                }
            }
#endif

            SettingsMadeBy(appID: appID)
        }
        #if os(iOS)
        .navigationTitle("Settings")
        #endif
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
