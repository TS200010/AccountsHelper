//
//  CategortMatcher.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 23/09/2025.
//

import Foundation
import CoreData

// Helps match input strings to a Category, using Core Data mappings
class CategoryMatcher {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// Normalise a string for comparison (UK style)
    private func normalize(_ string: String) -> String {
        return string
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
    
    // Find the best matching Category for an input string
    func matchCategory(for input: String) -> Category {
        let normalized = normalize(input)
        
        // fetch all stored mappings
        let request: NSFetchRequest<CategoryMapping> = CategoryMapping.fetchRequest()
        
        guard let mappings = try? context.fetch(request), !mappings.isEmpty else {
            return .unknown
        }
        
        // Apply weighted match search (highest usageCount wins if multiple)
        
        // 1. Exact match
        if let exact = mappings
            .filter({ $0.inputString == normalized })
            .max(by: { $0.usageCount < $1.usageCount }) {
            
            exact.incrementUsage()
            try? context.save()
            return exact.category
        }
        
        // 2. Prefix match
        if let prefix = mappings
            .filter({
                if let s = $0.inputString { return normalized.hasPrefix(s) }
                return false
            })
            .max(by: { $0.usageCount < $1.usageCount }) {
            
            prefix.incrementUsage()
            try? context.save()
            return prefix.category
        }
        
        // 3. Fuzzy match
        if let fuzzy = mappings
            .filter({
                if let s = $0.inputString { return normalized.contains(s) }
                return false
            })
            .max(by: { $0.usageCount < $1.usageCount }) {
            
            fuzzy.incrementUsage()
            try? context.save()
            return fuzzy.category
        }
        
        return .unknown
    }
    
    // Teach a new mapping (or update if exists)
    func teachMapping(for input: String, category: Category) {
        let normalized = normalize(input)
        
        let request: NSFetchRequest<CategoryMapping> = CategoryMapping.fetchRequest()
        request.predicate = NSPredicate(format: "inputString == %@", normalized)
        
        if let existing = try? context.fetch(request).first {
            existing.category = category
            existing.incrementUsage()
        } else {
            let mapping = CategoryMapping(context: context)
            mapping.inputString = normalized
            mapping.category = category
            mapping.usageCount = 1
        }
        
        try? context.save()
    }
}
