//
//  TabManager.swift
//
//
//  Created by Richard Witherspoon on 7/24/24.
//

import Foundation

public final class TabManager: ObservableObject {
    @Published public var selectedTab: Tab = .home
    
    public init() {}
}
