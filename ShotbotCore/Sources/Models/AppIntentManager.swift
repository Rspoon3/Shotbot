//
//  AppIntentManager.swift
//  ShotbotCore
//
//  Created by Ricky on 10/1/24.
//
import Foundation

@MainActor
public final class AppIntentManager: ObservableObject, Sendable {
    public static let shared = AppIntentManager()
    
    @Published public var selectTimeIntervalIntentID: Int?
}
