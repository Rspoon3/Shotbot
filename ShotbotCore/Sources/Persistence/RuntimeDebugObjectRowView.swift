//
//  RuntimeDebugObjectRowView.swift
//  ShotbotCore
//
//  Created by Ricky Witherspoon on 8/11/25.
//

#if DEBUG
import SwiftUI

struct RuntimeDebugObjectRowView: View {
    let object: DebugObject
    
    private var sortedAttributeKeys: [String] {
        Array(object.attributes.keys.sorted())
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(sortedAttributeKeys, id: \.self) { key in
                HStack {
                    Text(key)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(formatValue(object.attributes[key]))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Private
    
    private func formatValue(_ value: Any?) -> String {
        guard let value else { return "nil" }
        
        if let date = value as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        if let bool = value as? Bool {
            return bool ? "✓" : "✗"
        }
        
        let description = String(describing: value)
        if description.count > 100 {
            return String(description.prefix(97)) + "..."
        }
        return description
    }
}
#endif
