//
//  NotificationPermissionView.swift
//  Shotbot
//

import SwiftUI
import UserNotifications
import ReferralService

public struct NotificationPermissionView: View {
    @Binding var isPresented: Bool
    @State private var animateIcon = false
    
    // MARK: - Initializer
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Blue gradient background
            LinearGradient(
                gradient: Gradient(colors: [.blue, .indigo, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animated bell icon
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(animateIcon ? 1.2 : 1.0)
                    .rotationEffect(.degrees(animateIcon ? -10 : 10))
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                    .onAppear {
                        animateIcon = true
                    }
                
                VStack(spacing: 16) {
                    Text("🔔 Stay in the Loop")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Get notified about your referrals!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("We'll send you notifications when friends use your referral codes, so you know exactly when your rewards are ready.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    // Enable Notifications button
                    Button {
                        Task {
                            await requestNotificationPermissions()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .font(.title2)
                            Text("Enable Notifications")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 24)
                    
                    // Skip button
                    Button {
                        isPresented = false
                    } label: {
                        Text("Skip for now")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 20)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func requestNotificationPermissions() async {
        let notificationManager = NotificationManager()
        await notificationManager.requestNotificationPermissions()
        isPresented = false
    }
}

#Preview {
    NotificationPermissionView(isPresented: .constant(true))
}
