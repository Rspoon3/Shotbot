//
//  DeviceFramePreferencesView.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 3/28/26.
//

import SwiftUI
import Persistence
import SFSymbols

/// Displays the user's cached device frame preferences and allows removing individual entries.
struct DeviceFramePreferencesView: View {
    @EnvironmentObject private var persistenceManager: PersistenceManager

    // MARK: - Body

    var body: some View {
        List {
            Section {
                ForEach(sortedPreferences, id: \.key) { key, deviceFrame in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(deviceFrame)
                        Text(key)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contextMenu {
                        Button("Remove", symbol: .trash, role: .destructive) {
                            removePreference(forKey: key)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let key = sortedPreferences[index].key
                        removePreference(forKey: key)
                    }
                }
            } footer: {
                Text("Shotbot matches screenshots to device frames using image resolution. This is the only reliable information a screenshot contains. Certain settings, such as Display Zoom, can cause a screenshot's resolution to match a different device, resulting in the wrong frame being applied. When this happens, you can choose the correct device and Shotbot will remember your preference.")
            }
        }
        .navigationTitle("Device Frame Preferences")
    }

    // MARK: - Private Helpers

    private var sortedPreferences: [(key: String, value: String)] {
        persistenceManager.deviceFramePreferences
            .sorted(by: { $0.value < $1.value })
    }

    /// Parses a size key like "1170x2532" back into a `CGSize` and removes the preference.
    private func removePreference(forKey key: String) {
        let components = key.split(separator: "x")

        guard
            components.count == 2,
            let width = Double(components[0]),
            let height = Double(components[1])
        else {
            return
        }

        persistenceManager.removeDeviceFramePreference(for: CGSize(width: width, height: height))
    }
}
