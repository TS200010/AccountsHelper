//
//  VISACSVImporter.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/02/2026.
//

import Foundation
import CoreData

class VISACSVImporter: TxImporter {

    static var displayName: String = "VISA CSV Importer"
    static var account: ReconcilableAccounts = .VISA
    static var importType: ImportType = .csv

    @MainActor
    static func importTransactions(
        fileURL: URL,
        context: NSManagedObjectContext,
        mergeHandler: @MainActor (Transaction, Transaction) async -> MergeResult
    ) async -> ImportSummary {

        var createdTransactions: [Transaction] = []
        var importSummary = ImportSummary(
            processedCount: 0,
            exactDuplicateCount: 0,
            mergedCount: 0,
            keepExistingCount: 0,
            keepNewCount: 0,
            keepBothCount: 0
        )

        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            guard let headers = rows.first else { return importSummary }

            let matcher = CategoryMatcher(context: context)

            // Fetch existing transactions for duplicates
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "accountCD == %d", account.rawValue)
            let existingSnapshot = (try? context.fetch(fetchRequest)) ?? []

            for row in rows.dropFirst() {
                guard row.count == headers.count else { continue }

                let newTx = Transaction(context: context)
                importSummary.processedCount += 1

                for (index, header) in headers.enumerated() {
                    let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)

                    switch header.lowercased() {
                    case "transaction date":
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yyyy"
                        newTx.transactionDate = formatter.date(from: value)

                    case "transaction description":
                        newTx.payee = value
                        newTx.category = matcher.matchCategory(for: value)

                    case "transaction amount":
                        if let amt = Decimal(string: value.replacingOccurrences(of: ",", with: "")) {
//                            txAmountTemp = amt
                            newTx.txAmount = amt
                            newTx.debitCredit = amt >= 0 ? .DR : .CR
                        }

                    default:
                        break
                    }
                }

                // Default properties
                newTx.timestamp = Date()
                newTx.payer = .tony
                newTx.account = account
                newTx.currency = .UKL
                newTx.exchangeRate = 1

                // Snapshot including new creations
                let snapshot = createdTransactions + existingSnapshot

                // Check exact duplicates
                if isExactDuplicate(newTx: newTx, snapshot: snapshot) {
                    context.delete(newTx)
                    importSummary.exactDuplicateCount += 1
                    continue
                }

                // Check merge candidates
                if let existing = findMergeCandidateInSnapshot(newTx: newTx, snapshot: snapshot) {
                    let result = await mergeHandler(existing, newTx)
                    switch result {
                    case .merged:
                        if !createdTransactions.contains(existing) { createdTransactions.append(existing) }
                        context.delete(newTx)
                        importSummary.mergedCount += 1

                    case .keepExisting:
                        if !createdTransactions.contains(existing) { createdTransactions.append(existing) }
                        context.delete(newTx)
                        importSummary.keepExistingCount += 1

                    case .keepNew:
                        if !createdTransactions.contains(newTx) { createdTransactions.append(newTx) }
                        context.delete(existing)
                        importSummary.keepNewCount += 1

                    case .keepBoth:
                        if !createdTransactions.contains(existing) { createdTransactions.append(existing) }
                        if !createdTransactions.contains(newTx) { createdTransactions.append(newTx) }
                        importSummary.keepBothCount += 1

                    case .cancelMerge:
                        context.delete(newTx)
                        return importSummary
                    }
                } else {
                    createdTransactions.append(newTx)
                }
            }

            try context.save()
        } catch {
            print("Failed to import VISA CSV: \(error)")
        }
        
        return importSummary
    }
}
