//
//  AppTabNavigation.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/20/23.
//

import SwiftUI
import Models
import HomeFeature
import SettingsFeature
import Persistence

public struct AppTabNavigation: View {
    @EnvironmentObject var tabManager: TabManager
    @EnvironmentObject private var persistenceManager: PersistenceManager

    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            NavigationStack {
                HomeView(viewModel: .init())
                    .navigationBarTitleDisplayMode(ProcessInfo.processInfo.isiOSAppOnMac ? .inline : .automatic)
            }
            .tabItem {
                Label("Home", systemImage: "house")
                    .accessibility(label: Text("Home"))
            }
            .tag(Tab.home)
            
            NavigationStack {
                SettingsView()
                    .toolbar(ProcessInfo.processInfo.isiOSAppOnMac ? .hidden : .automatic)
            }
            .badge(persistenceManager.creditBalance)
            .tabItem {
                Label("Settings", systemImage: "gear")
                    .accessibility(label: Text("Settings"))
            }
            .tag(Tab.settings)
        }
    }
}

struct AppTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AppTabNavigation()
    }
}
