//
//  AppIntentManager.swift
//  ShotbotCore
//
//  Created by Ricky on 10/1/24.
//
import Foundation

public final class AppIntentManager: ObservableObject {
    public static let shared = AppIntentManager()
    
    @Published public var selectTimveIntervalIntentID: Int?
}
