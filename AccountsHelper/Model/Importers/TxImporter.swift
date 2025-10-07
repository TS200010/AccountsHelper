//
//  TxImporter.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import CoreData

enum ImportType {
    case csv
    case png
    // case pdf
    // case ofx
    // etc
}

// MARK: --- IxImporter Protocol

@MainActor
protocol TxImporter {
    static var displayName: String { get }
    static var paymentMethod: PaymentMethod { get }
    static var importType: ImportType { get }

    /// Import CSV and return Transactions, using the mergeHandler when duplicates are found.
    /// Transactions are created in a temporary child context, then saved into the main context.
    @MainActor
    static func importTransactions(
        fileURL: URL,
        context: NSManagedObjectContext,
        mergeHandler: @MainActor (Transaction, Transaction) async -> Transaction
    ) async -> [Transaction]

    /// Basic CSV parsing
    static func parseCSV(csvData: String) -> [[String]]

    /// Optional snapshot merge detection
    static func findMergeCandidateInSnapshot(newTx: Transaction, snapshot: [Transaction]) -> Transaction?
}

extension TxImporter {
    // MARK: --- Temporary Context Creation
    static func makeTemporaryContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let tempContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        tempContext.parent = parent
        return tempContext
    }

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
    static func findMergeCandidateInSnapshot(newTx: Transaction, snapshot: [Transaction]) -> Transaction? {
        for existing in snapshot {
            guard existing.txAmount == newTx.txAmount,
                  existing.paymentMethod == newTx.paymentMethod,
                  let existingDate = existing.transactionDate,
                  let newDate = newTx.transactionDate else {
                continue
            }

            // Allow transactionDate ± range: -7 days to +1 day
            let minDate = Calendar.current.date(byAdding: .day, value: -7, to: newDate)!
            let maxDate = Calendar.current.date(byAdding: .day, value: 1, to: newDate)!

            if existingDate >= minDate && existingDate <= maxDate {
                return existing
            }
        }
        return nil
    }
}
