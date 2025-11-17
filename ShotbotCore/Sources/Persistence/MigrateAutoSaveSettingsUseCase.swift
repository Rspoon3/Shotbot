//
//  MigrateAutoSaveSettingsUseCase.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 11/17/24.
//

import Foundation
import Models

/// Migrates legacy boolean autosave settings to the new enum-based options
///
/// TODO: Remove this migration after May 17, 2025 (6 months from creation)
/// By then, all users should have migrated to the new settings format.
@available(*, deprecated, message: "This migration can be removed after May 17, 2025")
public struct MigrateAutoSaveSettingsUseCase {
    private let userDefaults: UserDefaults

    // MARK: - Initializer

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Public

    /// Migrates the old boolean-based autosave settings to the new enum-based settings
    /// This should be called once during app initialization
    public func migrate() {
        migrateSetting(
            oldKey: "autoSaveToFiles",
            newKey: "autoSaveFilesOption"
        )

        migrateSetting(
            oldKey: "autoSaveToPhotos",
            newKey: "autoSavePhotosOption"
        )

        migrateSetting(
            oldKey: "autoCopy",
            newKey: "autoCopyOption"
        )
    }

    // MARK: - Private

    private func migrateSetting(oldKey: String, newKey: String) {
        // Check if migration has already been done
        guard userDefaults.object(forKey: newKey) == nil else {
            return
        }

        // Check if the old boolean value exists
        guard userDefaults.object(forKey: oldKey) != nil else {
            return
        }

        let oldBoolValue = userDefaults.bool(forKey: oldKey)

        // Convert boolean to enum
        let newOption: AutoSaveOption = oldBoolValue ? .all : .none

        // Save the new enum value
        userDefaults.set(newOption.rawValue, forKey: newKey)

        // Remove the old boolean value
        userDefaults.removeObject(forKey: oldKey)
    }
}
