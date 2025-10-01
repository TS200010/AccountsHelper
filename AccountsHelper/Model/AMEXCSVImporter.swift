//
//  AMEXCSVImporter.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 21/09/2025.
//


import Foundation
import CoreData



class AMEXCSVImporter: CSVImporter {
    
    @MainActor
    static func importTransactions(
        fileURL: URL,
        context: NSManagedObjectContext,
        mergeHandler: nonisolated(nonsending) (Transaction, Transaction) async -> Transaction
    ) async -> [Transaction] {
        return []
    }
    
    
//    @MainActor
//    static func importTransactions(
//        fileURL: URL,
//        context: NSManagedObjectContext,
//        mergeHandler: @MainActor @Sendable (Transaction, Transaction) async -> Transaction
//    ) async -> [Transaction] {
//        return []
//    }
    static var displayName: String = "AMEXCSVImporter"
    
    static var paymentMethod: PaymentMethod = .AMEX
    
    static func parseCSVToTransactionStruct(fileURL: URL) -> [TransactionStruct] {
        
        var transactions: [TransactionStruct] = []
        
        print("Starting CSV parse: \(fileURL.path)")
        
        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            guard let headers = rows.first else { return [] }

            let matcher = CategoryMatcher(context: PersistenceController.shared.container.viewContext)

            for row in rows.dropFirst() {
                guard row.count == headers.count else { continue }
                
                var tx = TransactionStruct()
                
                // Temp storage
                var txAmountTemp: Decimal = 0
                var extendedDetailsTemp: String?
                var addressTemp: String = ""
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
                        tx.transactionDate = formatter.date(from: value)
                    case "description":
                        tx.payee = value
                        tx.category = matcher.matchCategory(for: value)
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
                        tx.payer = Payer(value)
                    case "reference":
                        tx.reference = value
                    default:
                        break
                    }
                }
                
                tx.paymentMethod = paymentMethod
                tx.address = addressTemp
                tx.extendedDetails = extendedDetailsTemp
                if currencyParsedTemp == .GBP || currencyParsedTemp == .unknown {
                    tx.currency = .GBP
                    tx.exchangeRate = 1
                    tx.txAmount = txAmountTemp
                } else {
                    tx.currency = currencyParsedTemp
                    tx.exchangeRate = exchangeRateParsedTemp
                    tx.txAmount = txAmountParsedTemp
                    tx.commissionAmount = commissionAmountParsedTemp
                }
                
                tx.debitCredit = txAmountTemp >= 0 ? .DR : .CR
                transactions.append(tx)
            }
            
        } catch {
            print("Failed to read CSV: \(error)")
        }
        
        return transactions
    }

    
    static func findMergeCandidateInDatabase(newTx: TransactionStruct, context: NSManagedObjectContext) -> Transaction? {
        guard let newDate = newTx.transactionDate else { return nil }
        
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: newDate)!
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: newDate)!
       
        let txAmountForPredicate = (newTx.txAmount * 100) as NSDecimalNumber
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "txAmountCD == %@", txAmountForPredicate)
//            NSPredicate(format: "payee == %@", newTx.payee ?? ""),
//            NSPredicate(format: "paymentMethodCD == %d", newTx.paymentMethod.rawValue),
//            NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", startDate as NSDate, endDate as NSDate)
        ])
        
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Failed to fetch merge candidate: \(error)")
            return nil
        }
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
        var foreignCurrency: String?
        var commissionAmount: Decimal?
        var exchangeRate: Decimal?
        
        // Normalize whitespace and split by spaces
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
                    
                    // Clean number string (remove commas, trim spaces)
                    let rawAmount = tokens[index+3].replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
                    foreignSpendAmount = Decimal(string: rawAmount)

                    // Capture currency by consuming tokens until "Commission" keyword
                    var currencyTokens = [String]()
                    var j = index + 4
                    while j < tokens.count && tokens[j].lowercased() != "commission" {
                        currencyTokens.append(tokens[j])
                        j += 1
                    }
                    foreignCurrency = currencyTokens.joined(separator: " ").trimmingCharacters(in: .whitespaces)

                    // Move index forward so parser doesn’t reprocess tokens
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
        print ("foreignSpendAmount: \(foreignSpendAmount), foreignCurrency: \(foreignCurrency), commissionAmount: \(commissionAmount), exchangeRate: \(exchangeRate)")
        return (foreignSpendAmount, Currency.fromString( foreignCurrency ?? "" ), commissionAmount, exchangeRate)
    }
}
    

