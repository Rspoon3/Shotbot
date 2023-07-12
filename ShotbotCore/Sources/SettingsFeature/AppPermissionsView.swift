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
    let photoLibraryManager: PhotoLibraryManager
    
    init(photoLibraryManager: PhotoLibraryManager = .live) {
        self.photoLibraryManager = photoLibraryManager
    }
    
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

#if DEBUG
import Photos

struct AppPermissionsView_Previews: PreviewProvider {
    static let statuses : [PHAuthorizationStatus] = [
        .authorized,
        .denied,
        .limited,
        .notDetermined,
        .restricted
    ]
    
    static var previews: some View {
        ForEach(statuses, id: \.title) { status in
            NavigationView {
                AppPermissionsView(photoLibraryManager: .empty(status: status))
            }
            .previewDisplayName(status.title)
        }
    }
}
#endif
