//
//  AppPermissionsView.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/23/23.
//

import SwiftUI
import MediaManager

struct AppPermissionsView: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var photoLibraryManager: PhotoLibraryManager
    
    var body: some View {
        Form {
            Section {
                Label("Photo Library Additions", systemImage: "photo")
                    .badge(photoLibraryManager.photoAdditionStatus.title)
            }
            
            Section {
                Button {
                    openURL(.appSettings)
                } label: {
                    Label("System Settings", systemImage: "gear")
                }
            }
        }
        .navigationBarTitle("App Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .buttonStyle(.plain)
    }
}

struct AppPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppPermissionsView()
        }
    }
}
