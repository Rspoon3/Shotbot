//
//  SettingsView.swift
//  Shot Bot
//
//  Created by Richard Witherspoon on 4/20/23.
//

#if !os(macOS)
import SwiftUI
import Persistence
import Models
import Purchases

public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
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
                    viewModel.emailFeedbackButtonTapped()
                } label: {
                    Label {
                        Text(viewModel.emailButtonText)
                    } icon: {
                        if viewModel.isGeneratingLogs {
                            ProgressView()
                        } else {
                            Image(systemName: "envelope")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .disabled(viewModel.isGeneratingLogs)
                .alert(isPresented: $viewModel.showEmailAlert) {
                    Alert(
                        title: Text("Email Error"),
                        message: Text("Email services are not available on this device")
                    )
                }
                .alert(isPresented: $viewModel.showEmailFailedAlert) {
                    Alert(
                        title: Text("Email Error"),
                        message: Text("An error occurred sending your email")
                    )
                }
                .sheet(isPresented: $viewModel.showEmail) {
                    MailView(
                        recipients: ["richardwitherspoon3@gmail.com"],
                        subject: "Shot Bot Feedback",
                        message: viewModel.createFeedbackMessage(),
                        attachments: viewModel.attachments
                    ) { result in
                        if case .failure = result {
                            viewModel.showEmailFailedAlert = true
                        }
                    }
                }

                Button {
                    openURL(.appStore(appID: viewModel.appID))
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
            }
#endif

            SettingsMadeBy(appID: viewModel.appID)
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
#endif
