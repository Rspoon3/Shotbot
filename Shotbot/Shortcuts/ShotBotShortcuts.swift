//
//  ShotBotShortcuts.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 2/17/24.
//

import Foundation
import AppIntents

struct ShotBotShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateFramedScreenshotsIntent(),
            phrases: ["Create a framed screenshot with \(.applicationName)"],
            shortTitle: "Create Framed Screenshot",
            systemImageName: "photo"
        )
    }
}
