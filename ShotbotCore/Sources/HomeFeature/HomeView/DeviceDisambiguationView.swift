//
//  DeviceDisambiguationView.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 3/28/26.
//

import SwiftUI
import Models

/// A sheet that lets the user pick the correct device when a screenshot's resolution is ambiguous.
struct DeviceDisambiguationView: View {
    private let devices: [DeviceInfo]
    private let screenshot: UIImage
    private let onSelect: (DeviceInfo) -> Void

    // MARK: - Initializer

    init(devices: [DeviceInfo], screenshot: UIImage, onSelect: @escaping (DeviceInfo) -> Void) {
        self.devices = devices
        self.screenshot = screenshot
        self.onSelect = onSelect
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List(devices, id: \.deviceFrame) { device in
                Button {
                    onSelect(device)
                } label: {
                    DeviceRow(device: device)
                }
            }
            .navigationTitle("Select Device")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
    }

    // MARK: - Private Views

    private func DeviceRow(device: DeviceInfo) -> some View {
        HStack(spacing: 16) {
            if let framedImage = device.framed(using: screenshot) {
                Image(uiImage: framedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(device.displayName)
                    .font(.headline)

                if let scaledSize = device.scaledSize {
                    Text("Display Zoom")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Text("Native: \(Int(scaledSize.width)) × \(Int(scaledSize.height))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(Int(device.inputSize.width)) × \(Int(device.inputSize.height))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
