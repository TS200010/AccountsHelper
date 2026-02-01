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
    ) async -> ImportSummary {

        // MARK: --- Setup
        let tempContext = makeTemporaryContext(parent: context)
        var createdTransactions: [Transaction] = []
        var importSummary = ImportSummary(processedCount: 0, mergedCount: 0, keepExistingCount: 0, keepNewCount: 0, keepBothCount: 0)

        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            guard let headers = rows.first else { return importSummary }
            
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
//            let existingSnapshot = (try? context.fetch(fetchRequest)) ?? []
            let existingSnapshotIDs =
                (try? context.fetch(fetchRequest))?.map { $0.objectID } ?? []

            // MARK: --- Row Processing
            var shouldContinue = true
            for row in rows.dropFirst() where shouldContinue {
                guard row.count == headers.count else { continue }

                let newTx = Transaction(context: tempContext)
                importSummary.processedCount += 1

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
                        let cleaned = value.replacingOccurrences(of: ",", with: "")
                        if let balance = Decimal(string: cleaned) {
                            newTx.extendedDetails = Self.appendBalanceFingerprint(
                                balance,
                                to: newTx.extendedDetails
                            )
                        }

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
                
                let snapshot: [Transaction] =
                    createdTransactions +
                    existingSnapshotIDs.compactMap {
                        tempContext.object(with: $0) as? Transaction
                    }
                
                // MARK: --- Exact Duplicate Detection
                if Self.isExactDuplicate(
                    newTx: newTx,
                    snapshot: snapshot
                ) {
                    tempContext.delete(newTx)
                    continue
                }
                
                // MARK: --- Pair Detection
                if let counter = Self.findPairCandidateInSnapshot(
                    newTx: newTx,
                    snapshot: snapshot
                ) {
                    let pid = UUID()
                    newTx.pairID = pid
                    counter.pairID = pid
                }

                // MARK: --- Duplicate Checking
                if let existing = Self.findMergeCandidateInSnapshot(
                    newTx: newTx,
                    snapshot:
                        createdTransactions +
                        existingSnapshotIDs.compactMap {
                            tempContext.object(with: $0) as? Transaction
                        }
//                    snapshot: createdTransactions + existingSnapshot
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
                        importSummary.mergedCount += 1

                    case .keepExisting:
                        if !createdTransactions.contains(existing) {
                            createdTransactions.append(existing)
                        }
                        tempContext.delete(newTx)
                        importSummary.keepExistingCount += 1

                    case .keepNew:
                        if !createdTransactions.contains(newTx) {
                            createdTransactions.append(newTx)
                        }
                        tempContext.delete(existing)
                        importSummary.keepNewCount += 1

                    case .keepBoth:
                        if !createdTransactions.contains(existing) {
                            createdTransactions.append(existing)
                        }
                        if !createdTransactions.contains(newTx) {
                            createdTransactions.append(newTx)
                        }
                        importSummary.keepBothCount += 1
                        
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
            let objectIDs = createdTransactions
                .filter { !$0.isDeleted }
                .map { $0.objectID }
//            let objectIDs = createdTransactions.map { $0.objectID }
            let parentTransactions: [Transaction] = objectIDs.compactMap { id in
                context.object(with: id) as? Transaction
            }

            return importSummary

        } catch {
            print("Failed to import BofS CSV: \(error)")
            return importSummary
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
    
    // MARK: --- appendBalanceFingerprint
    private static func appendBalanceFingerprint(
        _ balance: Decimal,
        to existing: String?
    ) -> String {
        let fingerprint = "BOS_BAL_AFTER=\(balance)"
        guard let existing else { return fingerprint }
        return existing.contains("BOS_BAL_AFTER=")
            ? existing
            : existing + " | " + fingerprint
    }
    
    // MARK: --- isExactDuplicate
    static func isExactDuplicate(
        newTx: Transaction,
        snapshot: [Transaction]
    ) -> Bool {

        guard
            let newDate = newTx.transactionDate,
            let newFingerprint = newTx.extendedDetails
        else { return false }

        let calendar = Calendar.current

        for existing in snapshot {

            guard
                existing.account == newTx.account,
                existing.txAmount == newTx.txAmount,
                let existingDate = existing.transactionDate,
                let existingFingerprint = existing.extendedDetails
            else { continue }

            // Same statement day
            guard calendar.isDate(existingDate, inSameDayAs: newDate) else {
                continue
            }

            // Balance-after fingerprint match
            if existingFingerprint == newFingerprint {
                return true
            }
        }

        return false
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

