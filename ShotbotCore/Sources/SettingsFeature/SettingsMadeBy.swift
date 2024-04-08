//
//  SettingsMadeBy.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/23/23.
//

import SwiftUI

public struct SettingsMadeBy: View {
    let appID: Int
    @Environment(\.openURL) var openURL
    
    public init(appID: Int){
        self.appID = appID
    }
    
    public var body: some View {
        VStack{
            VStack{
#if os(visionOS)
                Image("AppIcon_1024")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .cornerRadius(5)
#else
                if let icon = Bundle.appIcon(type: .current) {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                        .cornerRadius(5)
                }
#endif
                
                Text(Bundle.appTitle ?? "N/A")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.systemGray))
                Text("Version \(Bundle.appVersion ?? "N/A") (\(Bundle.appBuild ?? "N/A"))")
#if os(visionOS)
                    .foregroundColor(Color(.systemGray))
#else
                    .foregroundColor(Color(.systemGray2))
#endif
                    .font(.caption)
                    .padding(.bottom)
            }
            .onTapGesture {
                openURL(.appStore(appID: appID))
            }
            VStack{
                Text("Designed and Developed")
                Text("by ") + Text("Ricky Witherspoon")
                    .foregroundColor(.accentColor)
            }
#if os(visionOS)
            .foregroundColor(Color(.systemGray))
#else
            .foregroundColor(Color(.systemGray2))
#endif
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .center)
            .onTapGesture{
                openURL(.personal)
            }
        }
        .padding(.top)
        .listRowBackground(Color(.systemGroupedBackground))
    }
}

struct SettingsMadeBy_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMadeBy(appID: 6450552843)
    }
}
