//
//  AMEXCSVImporter.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 21/09/2025.
//

import Foundation
import CoreData

class AMEXCSVImporter: TxImporter {
    
    static var displayName: String = "AMEX CSV Importer"
    static var paymentMethod: PaymentMethod = .AMEX
    static var importType: ImportType = .csv

    @MainActor
    static func importTransactions(
        fileURL: URL,
        context: NSManagedObjectContext,
        mergeHandler: @MainActor (Transaction, Transaction) async -> MergeResult
    ) async -> [Transaction] {
        var createdTransactions: [Transaction] = []
        
        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            guard let headers = rows.first else { return [] }
            guard headers.count > 5 else {
                print("Please export ALL fields from the AMEX WebSite")
                return []
            }

            let matcher = CategoryMatcher(context: context)

            // Fetch existing transactions from context for duplicate checking
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            let existingSnapshot = (try? context.fetch(fetchRequest)) ?? []

            var shouldContinue = true
            for row in rows.dropFirst() where shouldContinue {
                guard row.count == headers.count else { continue }
                
                let newTx = Transaction(context: context)
                
                // Temp variables
                var addressTemp = ""
                var txAmountTemp: Decimal = 0
                var extendedDetailsTemp: String?
                var txAmountParsedTemp: Decimal = 0
                var commissionAmountParsedTemp: Decimal = 0
                var exchangeRateParsedTemp: Decimal = 0
                var currencyParsedTemp: Currency = .unknown
                
                for (index, header) in headers.enumerated() {
                    let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    switch header.lowercased() {
                    case "date":
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yyyy"
                        newTx.transactionDate = formatter.date(from: value)
                        
                    case "description":
                        newTx.payee = value
                        newTx.category = matcher.matchCategory(for: value)
                        
                    case "amount":
                        txAmountTemp = Decimal(string: value.replacingOccurrences(of: ",", with: "")) ?? 0
                        
                    case "extended details":
                        extendedDetailsTemp = value
                        let parsed = parseExtendedDetails(value)
                        txAmountParsedTemp = parsed.foreignSpendAmount ?? 0
                        commissionAmountParsedTemp = parsed.commissionAmount ?? 0
                        exchangeRateParsedTemp = parsed.exchangeRate ?? 1
                        currencyParsedTemp = parsed.foreignCurrency ?? .unknown
                        
                    case "address":
                        addressTemp = value
                        
                    case "town/city":
                        addressTemp += ", " + value
                        
                    case "postcode":
                        addressTemp += ", " + value
                        
                    case "country":
                        addressTemp += ", " + value
                        
                    case "card member":
                        newTx.payer = Payer(value)
                        
                    case "reference":
                        newTx.reference = value
                        
                    default:
                        break
                    }
                }
                
                newTx.timestamp = Date()
                newTx.paymentMethod = paymentMethod
                newTx.address = addressTemp
                newTx.extendedDetails = extendedDetailsTemp
                
                if currencyParsedTemp == .GBP || currencyParsedTemp == .unknown {
                    newTx.currency = .GBP
                    newTx.exchangeRate = 1
                    newTx.txAmount = txAmountTemp
                } else {
                    newTx.currency = currencyParsedTemp
                    newTx.exchangeRate = exchangeRateParsedTemp
                    newTx.txAmount = txAmountParsedTemp
                    newTx.commissionAmount = commissionAmountParsedTemp
                }
                
                newTx.debitCredit = txAmountTemp >= 0 ? .DR : .CR
                
                
                // TODO: Date, Payee and Exchange rate should come from the importing TX as the starting point
                // TODO: Button should not be "Cancel, -- "Keep Both"
                // Check for duplicates in createdTransactions + existing context
                if let existing = Self.findMergeCandidateInSnapshot(newTx: newTx, snapshot: createdTransactions + existingSnapshot) {
                    
                    print("Existing: \(existing.comparableFieldsRepresentation())")
                    print("New: \(newTx.comparableFieldsRepresentation())")
                    
                    if existing.comparableFieldsRepresentation() == newTx.comparableFieldsRepresentation() {
                        // Already identical, skip
                        context.delete(newTx)
                        continue
                    }
                    
                    let result = await mergeHandler(existing, newTx)

                    switch result {
                    case .merged:
                        // existing has already been updated in MergeView
                        if !createdTransactions.contains(existing) {
                            createdTransactions.append(existing)
                        }
                        context.delete(newTx)

                    case .keepExisting:
                        if !createdTransactions.contains(existing) {
                            createdTransactions.append(existing)
                        }
                        context.delete(newTx)

                    case .keepNew:
                        if !createdTransactions.contains(newTx) {
                            createdTransactions.append(newTx)
                        }
                        context.delete(existing)

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
                    
                    

//                    if let mergedTx = await mergeHandler(existing, newTx) {
//                        // One transaction (merged, existing, or new) should be kept
//                        if !createdTransactions.contains(mergedTx) {
//                            createdTransactions.append(mergedTx)
//                        }
//
//                        // Delete the *other* one only if appropriate
//                        if mergedTx == existing {
//                            context.delete(newTx)
//                        } else if mergedTx == newTx {
//                            context.delete(existing)
//                        }
//                    } else {
//                        // Keep both (do not delete either)
//                        if !createdTransactions.contains(existing) {
//                            createdTransactions.append(existing)
//                        }
//                        if !createdTransactions.contains(newTx) {
//                            createdTransactions.append(newTx)
//                        }
//                    }

                    
//                    let mergedTx = await mergeHandler(existing, newTx)
//                    if !createdTransactions.contains(mergedTx) {
//                        createdTransactions.append(mergedTx)
//                    }
//                    context.delete(newTx)
                } else {
                    createdTransactions.append(newTx)
                }
            }
            
            try context.save()
        } catch {
            print("Failed to import AMEX CSV: \(error)")
        }
        
        return createdTransactions
    }

    
    // MARK: - CSV Parser (handles quotes and multi-line fields)
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
        
        return rows
    }

    
    static func parseExtendedDetails(_ details: String) -> (foreignSpendAmount: Decimal?, foreignCurrency: Currency?, commissionAmount: Decimal?, exchangeRate: Decimal?) {
        
        var foreignSpendAmount: Decimal?
        var foreignCurrency: Currency?
        var commissionAmount: Decimal?
        var exchangeRate: Decimal?
        
        let tokens = details.replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        var index = 0
        while index < tokens.count {
            let token = tokens[index].lowercased()
            
            switch token {
            case "foreign":
                if index + 3 < tokens.count,
                   tokens[index+1].lowercased() == "spend",
                   tokens[index+2].lowercased() == "amount:" {
                    
                    let rawAmount = tokens[index+3].replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
                    foreignSpendAmount = Decimal(string: rawAmount)

                    var currencyTokens = [String]()
                    var j = index + 4
                    while j < tokens.count && tokens[j].lowercased() != "commission" {
                        currencyTokens.append(tokens[j])
                        j += 1
                    }
                    foreignCurrency = Currency.fromString(currencyTokens.joined(separator: " ").trimmingCharacters(in: .whitespaces))
                    index = j - 1
                }
                
            case "commission":
                if index + 2 < tokens.count, tokens[index+1].lowercased() == "amount:" {
                    commissionAmount = Decimal(string: tokens[index+2])
                    index += 2
                }
                
            case "currency":
                if index + 3 < tokens.count, tokens[index+1].lowercased() == "exchange", tokens[index+2].lowercased() == "rate:" {
                    exchangeRate = Decimal(string: tokens[index+3])
                    index += 3
                }
                
            default:
                break
            }
            index += 1
        }
        
        return (foreignSpendAmount, foreignCurrency, commissionAmount, exchangeRate)
    }
}
