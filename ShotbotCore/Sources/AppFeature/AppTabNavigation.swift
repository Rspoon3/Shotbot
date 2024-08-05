//
//  AppTabNavigation.swift
//  Shot Bot
//
//  Created by Richard Witherspoon on 4/20/23.
//

import SwiftUI
import Models
import HomeFeature
import SettingsFeature

public struct AppTabNavigation: View {
    @EnvironmentObject var tabManager: TabManager

    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            NavigationView {
                HomeView(viewModel: .init())
            }
            #if !os(macOS)
            .navigationViewStyle(.stack)
            #endif
            .tabItem {
                Label("Home", systemImage: "house")
                    .accessibility(label: Text("Home"))
            }
            .tag(Tab.home)
            
            NavigationView {
                #if os(macOS)
                Text("Settings")
                #else
                SettingsView()
                #endif
            }
            #if !os(macOS)
            .navigationViewStyle(.stack)
            #endif
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
