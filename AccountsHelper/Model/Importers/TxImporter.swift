//
//  TxImporter.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import CoreData

// MARK: --- ImportType
enum ImportType {
    case csv
    case png
    // case pdf
    // case ofx
    // etc
}

// MARK: --- MergeResult
enum MergeResult {
    case merged
    case keepExisting
    case keepNew
    case keepBoth
    case cancelMerge
}

// MARK: --- ImportSummary
struct ImportSummary {
    var processedCount: Int
    var exactDuplicateCount: Int
    var mergedCount: Int
    var keepExistingCount: Int
    var keepNewCount: Int
    var keepBothCount: Int
}

// MARK: --- IxImporter Protocol
@MainActor
protocol TxImporter {
    static var displayName: String { get }
    static var account: ReconcilableAccounts { get }
    static var importType: ImportType { get }
    
    /// Import CSV and return Transactions, using the mergeHandler when duplicates are found.
    @MainActor
    static func importTransactions(
        fileURL: URL,
        context: NSManagedObjectContext,
        mergeHandler: @MainActor (Transaction, Transaction) async -> MergeResult
    ) async -> ImportSummary

    /// Basic CSV parsing
    static func parseCSV(csvData: String) -> [[String]]

    /// Optional snapshot merge detection
    static func findMergeCandidateInSnapshot(newTx: Transaction, snapshot: [Transaction]) -> Transaction?
    
    /// Optional exact duplicate detection
    static func isExactDuplicate(newTx: Transaction, snapshot: [Transaction]) -> Bool
}

extension TxImporter {

    // MARK: --- CSV Parser
    /// Handles quotes, multi-line fields, trims trailing empty headers
    static func parseCSV(csvData: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in csvData {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                currentRow.append(currentField)
                currentField = ""
            } else if (char == "\n" || char == "\r\n") && !insideQuotes {
                currentRow.append(currentField)
                rows.append(currentRow)
                currentRow = []
                currentField = ""
            } else {
                currentField.append(char)
            }
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        // Trim trailing empty fields from header row
        if var header = rows.first {
            while let last = header.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
                header.removeLast()
            }
            rows[0] = header
        }

        return rows
    }

    // MARK: --- Default Merge Candidate Matching
    static func findMergeCandidateInSnapshot(
        newTx: Transaction,
        snapshot: [Transaction]
    ) -> Transaction? {

        let calendar = Calendar.current

        for existing in snapshot {

            // Must be same account
            guard existing.account == newTx.account else { continue }
            
            // Skip closed transactions
            guard !existing.closed else { continue }
            
            // For AMEX, If reference exists and matches, treat as exact duplicate — skip
            // This is just a quick exit for accidental repeated import
//            if existing.account == .AMEX {
//                if let newRef = newTx.reference, !newRef.isEmpty,
//                   let existingRef = existing.reference, !existingRef.isEmpty,
//                   newRef == existingRef {
//                    // Matching reference — no need to merge
//                    return nil
//                }
//            }
            
            // AMEX reference is authoritative:
            // - Same non-empty reference = exact duplicate, so do not offer a merge.
            // - Different non-empty references = different transactions, so do not offer a merge.
            // - If either reference is empty, fall through to normal matching.
            if existing.account == .AMEX {
                let newRef = newTx.reference?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let existingRef = existing.reference?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if !newRef.isEmpty && !existingRef.isEmpty {
                    if newRef == existingRef {
                        return nil
                    } else {
                        continue
                    }
                }
            }
                
            // Must have dates
            guard let existingDate = existing.transactionDate,
                  let newDate = newTx.transactionDate else { continue }

            // -----------------------------
            // DAILY OD INT — STRICT ONLY and only relavent to BofS Transactions
            // -----------------------------
            if isDailyODInterest(newTx) {

                // Strict duplicate: same amount AND same statement day
                if existing.txAmount == newTx.txAmount &&
                   calendar.isDate(existingDate, inSameDayAs: newDate) {
                    return nil
                }

                // Otherwise: NOT a merge candidate — keep scanning
                continue
            }

            // --------------------------------
            // NORMAL TRANSACTIONS — FUZZY
            // --------------------------------
            guard existing.txAmount == newTx.txAmount else { continue }

            let minDate = calendar.date(byAdding: .day, value: -7, to: newDate)!
            let maxDate = calendar.date(byAdding: .day, value: 1, to: newDate)!

            if existingDate >= minDate && existingDate <= maxDate {
                return existing
            }
        }

        return nil
    }
}

extension TxImporter {

    // MARK: --- Exact Duplicate Detection
    /// Checks if a new transaction is an exact duplicate of any transaction in the snapshot.
    /// For AMEX, also considers the reference field.
    static func isExactDuplicate(newTx: Transaction, snapshot: [Transaction]) -> Bool {
        guard let newDate = newTx.transactionDate else { return false }

        let calendar = Calendar.current

        for existing in snapshot {
            // Must be same account
            guard existing.account == newTx.account else { continue }

            // Skip closed transactions
            guard !existing.closed else { continue }

//            // AMEX shortcut: reference-based duplicates
//            if existing.account == .AMEX,
//               let newRef = newTx.reference, !newRef.isEmpty,
//               let existingRef = existing.reference, !existingRef.isEmpty,
//               newRef == existingRef {
//                return true
//            }
            // For AMEX, treat references as authoritative:
            // - If both have non-empty references and they match -> exact duplicate -> skip merging
            // - If either has a non-empty reference and they differ -> do NOT consider merge candidate (skip this existing)
            if existing.account == .AMEX {
                let newRef = newTx.reference?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let existingRef = existing.reference?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !newRef.isEmpty && !existingRef.isEmpty {
                    if newRef == existingRef {
                        // references match -> not a merge (exact duplicate), stop looking
                        return true
                    } else {
                        // references differ -> explicitly not a merge candidate for AMEX
                        continue
                    }
                }
                // if refs are empty, fall through to fuzzy matching
            }

            // Must have dates
            guard let existingDate = existing.transactionDate else { continue }

            // DAILY OD INT strict duplicates (relevant for BofS)
            if isDailyODInterest(newTx) {
                if existing.txAmount == newTx.txAmount &&
                   calendar.isDate(existingDate, inSameDayAs: newDate) {
                    return true
                }
                continue
            }

            // Normal fuzzy duplicates: same amount + date window
            guard existing.txAmount == newTx.txAmount else { continue }

            let minDate = calendar.date(byAdding: .day, value: -7, to: newDate)!
            let maxDate = calendar.date(byAdding: .day, value: 1, to: newDate)!

            if existingDate >= minDate && existingDate <= maxDate {
                return true
            }
        }

        return false
    }
}


// MARK: --- Helpers
extension TxImporter {
    
    private static func isDailyODInterest(_ tx: Transaction) -> Bool {
        tx.payee?.hasPrefix("DAILY OD INT") == true
    }
    
}

