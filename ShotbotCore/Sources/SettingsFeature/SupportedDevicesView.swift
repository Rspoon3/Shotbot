//
//  SupportedDevicesView.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/23/23.
//

import SwiftUI

struct SupportedDevicesView: View {
    @State private var searchText = ""
    
    var filteredResults: String {
        return ""
    }
    
    
    var deviceTypes: [DeviceType] {
        if searchText.isEmpty {
            return DeviceType.allCases
        } else {
            return DeviceType.allCases.filter {
                !filtered(for: $0).isEmpty
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Form {
            ForEach(deviceTypes) { type in
                Section(type.rawValue) {
                    ForEach(filtered(for: type), id: \.self) {
                        Text($0)
                    }
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText)
        .animation(.default, value: searchText)
        .overlay {
            if deviceTypes.isEmpty {
                Label("No Results", systemImage: "macbook.and.iphone")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func filtered(for type: DeviceType) -> [String] {
        if searchText.isEmpty {
            return type.supportedDevices
        } else {
            return type.supportedDevices.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SupportedDevicesView()
        }
    }
}
