//
//  CategoryMapping.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 23/09/2025.
//

import Foundation

extension CategoryMapping {
    
    var category: Category {
        get { Category(rawValue: categoryRawValue) ?? .unknown }
        set { categoryRawValue = newValue.rawValue }
    }
 
    func incrementUsage() {
        if usageCount < Int32.max {
            usageCount += 1
        }
        // If already at Int32.max, do nothing (saturating counter)
    }
}
