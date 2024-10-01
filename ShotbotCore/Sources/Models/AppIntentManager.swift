//
//  AppIntentManager.swift
//  ShotbotCore
//
//  Created by Ricky on 10/1/24.
//
import Foundation

public final class AppIntentManager: ObservableObject {
    public static let shared = AppIntentManager()
    
    @Published public var selectDurationIntentID: Int? { didSet {
        print("RSW set here \(selectDurationIntentID)")
    }}
}
