//
//  CategortMatcher.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 23/09/2025.
//

import Foundation
import CoreData

/// Helps match input strings to a Category, using Core Data mappings
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

    // MARK: - Matching
    /// Find the best matching Category for an input string
    func matchCategory(for input: String) -> Category {
        let normalized = normalize(input)

        let request: NSFetchRequest<CategoryMapping> = CategoryMapping.fetchRequest()

        guard let mappings = try? context.fetch(request), !mappings.isEmpty else {
            return .unknown
        }

        // 1. Exact match (highest usageCount preferred)
        if let exact = mappings
            .filter({ $0.inputString?.lowercased() == normalized })
            .max(by: { $0.usageCount < $1.usageCount }) {

            exact.incrementUsage()
            saveContextSilently()
            return exact.category
        }

//        // 2. Prefix match
//        if let prefix = mappings
//            .filter({ ($0.inputString?.isEmpty == false) && normalized.hasPrefix($0.inputString!.lowercased()) })
//            .max(by: { $0.usageCount < $1.usageCount }) {
//
//            prefix.incrementUsage()
//            saveContextSilently()
//            return prefix.category
//        }
        
        // 2. Prefix match with case/whitespace/diacritic-insensitive Unicode normalization
        if let prefix = mappings
            .filter({
                guard let s = $0.inputString, !s.isEmpty else { return false }

                let lhs = normalized
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

                let rhs = s
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

                return lhs.hasPrefix(rhs)
            })
            .max(by: { $0.usageCount < $1.usageCount }) {

            prefix.incrementUsage()
            DispatchQueue.main.async {
                self.saveContextSilently()
            }
            return prefix.category
        }

        // 3. Fuzzy (contains)
        if let fuzzy = mappings
            .filter({ ($0.inputString?.isEmpty == false) && normalized.contains($0.inputString!.lowercased()) })
            .max(by: { $0.usageCount < $1.usageCount }) {

            fuzzy.incrementUsage()
            saveContextSilently()
            return fuzzy.category
        }

        return .unknown
    }

    private func saveContextSilently() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            NSLog("CategoryMatcher save error: \(error)")
        }
    }

    // MARK: - Teach Mapping (automatic reapply)
    /// Teach a new mapping. This will create or update a CategoryMapping and then reapply to unknown transactions.
    func teachMapping(for input: String, category: Category) {
        let normalized = normalize(input)

        context.performAndWait {
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

            do {
                try context.save()
            } catch {
                NSLog("Failed to save new mapping: \(error)")
            }

            // 🔁 Immediately reapply the mapping to unknown transactions.
            // We call the reapply method on the same context to keep it simple and
            // to ensure UI @FetchRequest observers update.
            self.reapplyMappingsToUnknownTransactions()
        }
    }

    // MARK: - Reapply to unknown transactions
    /// Scans Transactions with category == .unknown and attempts to match them using the mappings.
    /// Uses the same context (so UI will see the changes immediately).
    func reapplyMappingsToUnknownTransactions() {
        // Perform on context's queue
        context.performAndWait {
            
            let allTx: [Transaction] = (try? context.fetch(Transaction.fetchRequest())) ?? []
            for tx in allTx {
                print("categoryCD: \(tx.categoryCD), payee: \(tx.payee ?? "")")
            }
            
            let txRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            txRequest.predicate = NSPredicate(format: "categoryCD == %d OR categoryCD == 0", Category.unknown.rawValue)
            print (Category.unknown.rawValue)
            guard let transactions = try? context.fetch(txRequest), !transactions.isEmpty else {
                NSLog("Failed to fetch transactions during reapply.")
                return
            }

            var changed = false
            for tx in transactions {
                // Use `payee` as the text to match against
                if let payee = tx.payee, !payee.isEmpty {
                    let matched = self.matchCategory(for: payee)
                    if matched != .unknown {
                        tx.category = matched
                        changed = true
                    }
                }
            }

            if changed {
                do {
                    try context.save()
                } catch {
                    NSLog("Failed to save transactions during reapply: \(error)")
                }
            }
        }
    }
}
