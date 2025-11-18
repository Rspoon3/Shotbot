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
import ReferralFeature
import ReferralService

public struct SettingsView: View {
    let appID = 6450552843
    @State private var logExporter = LogExporter()
    @State private var deviceFrameCreations = 0
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var persistenceManager: PersistenceManager
    @StateObject private var referralViewModel = ReferralViewModel()
    @AppStorage("useProductionCloudKit") private var useProductionCloudKit = false
    @AppStorage("useReferralLocalHostURL") private var useReferralLocalHostURL = false
    @State private var cloudKitID: String = "Loading..."
    @State private var isTestingPush = false
    @State private var testPushMessage = ""
    @State private var showTestPushAlert = false
    @State private var isClearingDatabase = false
    @State private var clearDatabaseMessage = ""
    @State private var showClearDatabaseAlert = false
    @State private var showConfirmDatabaseClear = false
    @State private var showNotificationPermission = false

    private let referralService = ReferralService()
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        Form {
            Section {
                Picker("Auto save to files", selection: $persistenceManager.autoSaveFilesOption) {
                    ForEach(AutoActionOption.allCases) { option in
                        Text(option.rawValue)
                            .tag(option)
                    }
                }

                Picker("Auto save to photos", selection: $persistenceManager.autoSavePhotosOption) {
                    ForEach(AutoActionOption.allCases) { option in
                        Text(option.rawValue)
                            .tag(option)
                    }
                }

                Picker("Auto copy", selection: $persistenceManager.autoCopyOption) {
                    ForEach(AutoActionOption.allCases) { option in
                        Text(option.rawValue)
                            .tag(option)
                    }
                }

                Toggle("Auto delete screenshots", isOn: $persistenceManager.autoDeleteScreenshots)
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
                    ReferralView(
                        viewModel: referralViewModel,
                        referralDataStorage: persistenceManager
                    )
                    .fullScreenCover(isPresented: $showNotificationPermission) {
                        NotificationPermissionView(isPresented: $showNotificationPermission)
                    }
                    .onAppear {
                        guard !persistenceManager.hasShownNotificationPermission else { return }
                        showNotificationPermission = true
                        persistenceManager.hasShownNotificationPermission = true
                    }
                } label: {
                    Label {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Referrals")
                                if persistenceManager.creditBalance > 0 {
                                    Text("\(persistenceManager.creditBalance) \(persistenceManager.creditBalance == 1 ? "credit" : "credits") available")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                } else {
                                    Text("Share with friends to earn rewards")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if persistenceManager.creditBalance > 0 {
                                Image(systemName: "\(persistenceManager.creditBalance).circle.fill")
                                    .foregroundStyle(.white, .red)
                            }
                        }
                    } icon: {
                        Image(systemName: "person.2")
                            .foregroundColor(.blue)
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
            Section("App") {
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
                    "Is Subscribed",
                    value: persistenceManager.isSubscribed.description
                )
                
                Stepper(
                    "Frames Creations: \(persistenceManager.deviceFrameCreations.formatted())",
                    value: .init(get: {
                        deviceFrameCreations
                    }, set: { value in
                        deviceFrameCreations = value
                        persistenceManager.deviceFrameCreations = value
                    })
                )
                .onAppear {
                    deviceFrameCreations = persistenceManager.deviceFrameCreations
                }
                
                Picker("Subscription Override", selection: $persistenceManager.subscriptionOverride) {
                    ForEach(PersistenceManager.SubscriptionOverrideMethod.allCases) { type in
                        Text(type.id)
                            .tag(type)
                    }
                }
            }
            
            Section("Referral Environment") {
                Toggle("Use Production CloudKit", isOn: $useProductionCloudKit)
                Toggle("Use Production Local Host URL", isOn: $useReferralLocalHostURL)
            }
            
            Section("Referral Data") {
                Stepper(
                    "Referral Banner Loads: \(persistenceManager.referralBannerCount.formatted())",
                    value: $persistenceManager.referralBannerCount
                )
                
                NavigationLink(
                    "View All My Codes",
                    destination: AllReferralCodesView(referralViewModel: referralViewModel)
                )
                
                NavigationLink(
                    "Code Rules",
                    destination: CodeRulesView(referralViewModel: referralViewModel)
                )
                
                LabeledContent(
                    "Credit Balance",
                    value: persistenceManager.creditBalance.formatted()
                )
                
                LabeledContent(
                    "Can Enter Referral Code",
                    value: persistenceManager.canEnterReferralCode.description
                )
                
                LabeledContent("CloudKit ID", value: cloudKitID)
                    .task {
                        await loadCloudKitID()
                    }
            }
            
            Section("Push Notifications") {
                Button {
                    Task {
                        await testPushNotification()
                    }
                } label: {
                    HStack {
                        if isTestingPush {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Label("Test Push Notification", systemImage: "bell.badge")
                    }
                }
                .disabled(isTestingPush)
            }
            
            Section("Development Database") {
                Button {
                    showConfirmDatabaseClear = true
                } label: {
                    HStack {
                        if isClearingDatabase {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Clear Development Database")
                    }
                }
                .disabled(isClearingDatabase)
            }
            .alert("Database Clear", isPresented: $showClearDatabaseAlert) {
                Button("OK") { }
            } message: {
                Text(clearDatabaseMessage)
            }
            .alert("Clear Development Database", isPresented: $showConfirmDatabaseClear) {
                Button("Cancel", role: .cancel) { }
                Button("Clear Database", role: .destructive) {
                    Task {
                        await clearDevelopmentDatabase()
                    }
                }
            } message: {
                Text("This will permanently delete all data from the development database. This action cannot be undone.")
            }
            .alert("Test Push Notification", isPresented: $showTestPushAlert) {
                Button("OK") { }
            } message: {
                Text(testPushMessage)
            }
#endif
            
            SettingsMadeBy(appID: appID)
        }
#if os(iOS)
        .navigationTitle("Settings")
#endif
        .buttonStyle(.plain)
    }
    
#if DEBUG
    private func clearDevelopmentDatabase() async {
        isClearingDatabase = true
        
        defer {
            showClearDatabaseAlert = true
            isClearingDatabase = false
        }
        
        do {
            let message = try await referralService.clearDevelopmentDatabase()
            clearDatabaseMessage = message
        } catch {
            clearDatabaseMessage = "Failed to clear database: \(error.localizedDescription)"
        }
    }

    private func loadCloudKitID() async {
        cloudKitID = (try? await referralService.getCurrentCloudKitID()) ?? "Error"
    }
    
    private func testPushNotification() async {
        isTestingPush = true
        
        defer {
            showTestPushAlert = true
            isTestingPush = false
        }
        
        do {
            let response = try await referralService.testPushNotification()
            testPushMessage = response.message
        } catch {
            testPushMessage = "Failed to test push notification: \(error.localizedDescription)"
        }
    }
#endif
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(PersistenceManager.shared)
        }
    }
}
