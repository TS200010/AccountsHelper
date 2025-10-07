//
//  CategoryMapping.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 23/09/2025.
//

import Foundation

extension CategoryMapping {
    
    // MARK: --- Category Property
    var category: Category {
        get { Category(rawValue: categoryRawValue) ?? .unknown }
        set { categoryRawValue = newValue.rawValue }
    }
    
    // MARK: --- Usage Counter
    func incrementUsage() {
        if usageCount < Int32.max {
            usageCount += 1
        }
        // Saturating counter: do nothing if already at Int32.max
    }
}
