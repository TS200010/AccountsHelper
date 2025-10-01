import Foundation
import CoreData

class BofSCSVImporter: CSVImporter {

    static var displayName: String = "BofS CSV Importer"
    static var paymentMethod: PaymentMethod = .BofSPV

    @MainActor
    static func importTransactions(
        fileURL: URL,
        context: NSManagedObjectContext,
        mergeHandler: @Sendable (Transaction, Transaction) async -> Transaction
    ) async -> [Transaction] {
        var createdTransactions: [Transaction] = []

        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            guard let headers = rows.first else { return [] }

            let matcher = CategoryMatcher(context: context)
            var accountTemp = ""

            // Fetch existing transactions from context for duplicate checking
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            let existingSnapshot = (try? context.fetch(fetchRequest)) ?? []

            for row in rows.dropFirst() {
                guard row.count == headers.count else { continue }

                let newTx = Transaction(context: context)

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

                newTx.paymentMethod = paymentMethod
                newTx.accountNumber = accountTemp
                newTx.currency = .GBP
                newTx.exchangeRate = 1

                // Check for duplicates in createdTransactions + existing context
                if let existing = Self.findMergeCandidateInSnapshot(newTx: newTx, snapshot: createdTransactions + existingSnapshot) {
                    let mergedTx = await mergeHandler(existing, newTx)
                    if !createdTransactions.contains(mergedTx) {
                        createdTransactions.append(mergedTx)
                    }
                    // Delete the newTx since mergeHandler is responsible for updating existing
                    context.delete(newTx)
                } else {
                    createdTransactions.append(newTx)
                }
            }

            try context.save()

        } catch {
            print("Failed to import BofS CSV: \(error)")
        }

        return createdTransactions
    }
}
