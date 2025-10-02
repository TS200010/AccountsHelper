import Foundation
import CoreData

class BofSCSVImporter: TxImporter {

    static var displayName: String = "BofS CSV Importer"
    static var paymentMethod: PaymentMethod = .BofSPV
    static var importType: ImportType = .csv

    @MainActor
    static func importTransactions(
        fileURL: URL,
        context: NSManagedObjectContext,
        mergeHandler: @Sendable (Transaction, Transaction) async -> Transaction
    ) async -> [Transaction] {
        // Create a child context for safe import
        let tempContext = makeTemporaryContext(parent: context)
        var createdTransactions: [Transaction] = []

        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            guard let headers = rows.first else { return [] }

            let matcher = CategoryMatcher(context: tempContext)
            var accountTemp = ""

            // Snapshot of existing transactions from parent context
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            let existingSnapshot = (try? context.fetch(fetchRequest)) ?? []

            for row in rows.dropFirst() {
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
                            newTx.txAmount = credit
                            newTx.debitCredit = .CR
                        }

                    case "balance":
                        break

                    default:
                        break
                    }
                }

                newTx.timestamp = Date()
                newTx.payer = .tony
                newTx.paymentMethod = paymentMethod
                newTx.accountNumber = accountTemp
                newTx.currency = .GBP
                newTx.exchangeRate = 1

                // Check for duplicates across new + existing
                if let existing = Self.findMergeCandidateInSnapshot(newTx: newTx,
                                                                   snapshot: createdTransactions + existingSnapshot) {

                    if existing.comparableFieldsRepresentation() == newTx.comparableFieldsRepresentation() {
                        // Exactly the same → skip
                        tempContext.delete(newTx)
                        continue
                    }

                    let mergedTx = await mergeHandler(existing, newTx)
                    if !createdTransactions.contains(mergedTx) {
                        createdTransactions.append(mergedTx)
                    }
                    tempContext.delete(newTx) // merged into existing
                } else {
                    createdTransactions.append(newTx)
                }
            }

            // Save child context → pushes into parent
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
}

