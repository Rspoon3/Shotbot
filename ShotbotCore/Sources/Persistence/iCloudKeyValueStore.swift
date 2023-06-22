//
//  iCloudKeyValueStore.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 5/18/23.
//

import Foundation

@propertyWrapper
public struct iCloudKeyValueStore<T> {
    private var key: String
    private var defaultValue: T
    private var store: NSUbiquitousKeyValueStore
    
    public init(
        wrappedValue value: T,
        _ key: String,
        store: NSUbiquitousKeyValueStore = .default
    ) {
        self.key = key
        self.defaultValue = value
        self.store = store
    }
    
    public var wrappedValue: T {
        get {
            return store.object(forKey: key) as? T ?? defaultValue
        }
        set {
            store.set(newValue, forKey: key)
            store.synchronize()
        }
    }
}
