//
//  BofSCSVImporter.swift
//  AccountsHelper
//
//  Created by ChatGPT on 07/10/2025.
//

import Foundation
import CoreData

class BofSCSVImporter: TxImporter {

    static var displayName: String = "BofS CSV Importer"
    static var account: ReconcilableAccounts = .unknown
    static var importType: ImportType = .csv

    @MainActor
    static func importTransactions(
        fileURL: URL,
        context: NSManagedObjectContext,
        mergeHandler: @MainActor (Transaction, Transaction) async -> MergeResult
    ) async -> [Transaction] {

        // MARK: --- Setup
        let tempContext = makeTemporaryContext(parent: context)
        var createdTransactions: [Transaction] = []

        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            guard let headers = rows.first else { return [] }
            
            guard
                let accountIndex = headers.firstIndex(where: { $0.lowercased() == "account number" }),
                rows.count > 1
            else {
                throw ImportError.missingAccountNumberColumn
            }

            let rawAccountNumber = rows[1][accountIndex]
                .trimmingCharacters(in: .whitespaces)
                .filter(\.isNumber)

            guard let account =
                    ReconcilableAccounts.fromAccountNumber(rawAccountNumber)
            else {
                throw ImportError.unknownAccount(rawAccountNumber)
            }
            
            let matcher = CategoryMatcher(context: tempContext)
            var accountTemp = ""

            // Snapshot of existing transactions from parent context
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            let existingSnapshot = (try? context.fetch(fetchRequest)) ?? []

            // MARK: --- Row Processing
            var shouldContinue = true
            for row in rows.dropFirst() where shouldContinue {
                guard row.count == headers.count else { continue }

                let newTx = Transaction(context: tempContext)

                for (index, header) in headers.enumerated() {
                    let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)

                    switch header.lowercased() {
                    case "transaction date":
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yyyy"
                        newTx.transactionDate = formatter.date(from: value)

                    case "transaction type":
                        newTx.explanation = value

                    case "sort code":
                        accountTemp = value

                    case "account number":
                        accountTemp += " " + value

                    case "transaction description":
                        newTx.payee = value
                        newTx.category = matcher.matchCategory(for: value)

                    case "debit amount":
                        if let debit = Decimal(string: value.replacingOccurrences(of: ",", with: "")), debit > 0 {
                            newTx.txAmount = debit
                            newTx.debitCredit = .DR
                        }

                    case "credit amount":
                        if let credit = Decimal(string: value.replacingOccurrences(of: ",", with: "")), credit > 0 {
                            newTx.txAmount = -credit
                            newTx.debitCredit = .CR
                        }

                    case "balance":
                        break

                    default:
                        break
                    }
                }

                // MARK: --- Default Properties
                newTx.timestamp = Date()
                newTx.payer = .tony
                newTx.account = account
                newTx.accountNumber = accountTemp
                newTx.currency = .GBP
                newTx.exchangeRate = 1
                
                // MARK: --- Pair Detection
                if let counter = Self.findPairCandidateInSnapshot(
                    newTx: newTx,
                    snapshot: createdTransactions + existingSnapshot
                ) {
                    let pid = UUID()
                    newTx.pairID = pid
                    counter.pairID = pid
                }


                // MARK: --- Duplicate Checking
                if let existing = Self.findMergeCandidateInSnapshot(
                    newTx: newTx,
                    snapshot: createdTransactions + existingSnapshot
                ) {

                    if existing.comparableFieldsRepresentation() == newTx.comparableFieldsRepresentation() {
                        // Exactly the same → skip
                        tempContext.delete(newTx)
                        continue
                    }

                    let result = await mergeHandler(existing, newTx)

                    switch result {
                    case .merged:
                        // existing has already been updated in MergeView
                        if !createdTransactions.contains(existing) {
                            createdTransactions.append(existing)
                        }
                        tempContext.delete(newTx)

                    case .keepExisting:
                        if !createdTransactions.contains(existing) {
                            createdTransactions.append(existing)
                        }
                        tempContext.delete(newTx)

                    case .keepNew:
                        if !createdTransactions.contains(newTx) {
                            createdTransactions.append(newTx)
                        }
                        tempContext.delete(existing)

                    case .keepBoth:
                        if !createdTransactions.contains(existing) {
                            createdTransactions.append(existing)
                        }
                        if !createdTransactions.contains(newTx) {
                            createdTransactions.append(newTx)
                        }
                        
                    case .cancelMerge:
                        shouldContinue = false
                    }

                } else {
                    createdTransactions.append(newTx)
                }
            }

            // MARK: --- Save Contexts
            try tempContext.save()
            try context.save()

            // Re-fetch results in parent context
            let objectIDs = createdTransactions.map { $0.objectID }
            let parentTransactions: [Transaction] = objectIDs.compactMap { id in
                context.object(with: id) as? Transaction
            }

            return parentTransactions

        } catch {
            print("Failed to import BofS CSV: \(error)")
            return []
        }
    }
    
    // MARK: --- findPairCandidateInSnapshot
    static func findPairCandidateInSnapshot(
        newTx: Transaction,
        snapshot: [Transaction]
    ) -> Transaction? {
        guard newTx.pairID == nil else { return nil }
        
        let wip = snapshot.first { existing in

            // 1. Must be unpaired
            guard existing.pairID == nil else { return false }

            // 2. Opposite sign
            let oppositeSign =
                (existing.txAmount < 0 && newTx.txAmount > 0) ||
                (existing.txAmount > 0 && newTx.txAmount < 0)

            // 3. Same absolute amount
            let sameAmount =
                existing.txAmount.magnitude == newTx.txAmount.magnitude

            // 4. Same date
            let sameDate = existing.transactionDate == newTx.transactionDate

            // 5. Different accounts
            let differentAccount = existing.account != newTx.account

            // 6. Transfer-like
//            let looksLikeTransfer =
//                Self.looksLikeTransfer(existing) &&
//                Self.looksLikeTransfer(newTx)

            // 7. Optional description cross-reference
//            let descriptionMatch =
//                Self.descriptionsReferenceEachOther(existing, newTx)

            return
                oppositeSign &&
                sameAmount &&
                sameDate &&
                differentAccount// &&
//                looksLikeTransfer // &&
//                descriptionMatch
        }

        return wip
    }
    
    // MARK: --- looksLikeTransfer
//    static func looksLikeTransfer(_ tx: Transaction) -> Bool {
//        guard let explanation = tx.explanation?.uppercased() else { return false }
//        return explanation.contains("TFR")
//            || explanation.contains("FPI")
//            || explanation.contains("FPO")
//    }
//    
    // MARK: --- descriptionsReferenceEachOther
//    static func descriptionsReferenceEachOther(_ a: Transaction, _ b: Transaction) -> Bool {
//        guard
//            let aRef = a.accountNumber,
//            let bRef = b.accountNumber
//        else { return true } // allow if missing
//
//        return a.payee?.contains(bRef) == true
//            || b.payee?.contains(aRef) == true
//    }



}
