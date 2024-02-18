//
//  AppTabNavigation.swift
//  Shot Bot
//
//  Created by Richard Witherspoon on 4/20/23.
//

import SwiftUI
import HomeFeature
import SettingsFeature

public struct AppTabNavigation: View {
    @State private var tabSelection = Tab.home
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        TabView(selection: $tabSelection) {
            NavigationView {
                HomeView(
                    viewModel: HomeViewModel(
                        photoLibraryManager: .live
                    )
                )
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Home", systemImage: "house")
                    .accessibility(label: Text("Home"))
            }
            .tag(Tab.home)
            
            NavigationView {
                SettingsView()
            }
            .navigationViewStyle(.stack)
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


import AppIntents
import Shortcuts

public struct ShotbotAppIntentsPackage: AppIntentsPackage {
    public static var includedPackages: [AppIntentsPackage.Type] = [
        ShotBotAppIntents.self
    ]
}
