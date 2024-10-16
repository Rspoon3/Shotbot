//
//  HomeViewType.swift
//
//
//  Created by Richard Witherspoon on 5/18/24.
//

import Foundation

/// The type of view that will be show for individual images. Either a grid or a tabbed view.
public enum HomeViewType: String, CaseIterable, Identifiable, Sendable {
    case grid = "Grid"
    case tabbed = "Tabbed"
    
    public var id: String { rawValue }
}
