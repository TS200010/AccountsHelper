//
//  BofSCSVImporter.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 30/09/2025.
//

import Foundation
import CoreData

class BofSCSVImporter: CSVImporter {
    
    static var displayName: String = "BofS CSV Importer"
    
    static var paymentMethod: PaymentMethod = .BofSPV
    
    static func parseCSVToTransactionStruct(fileURL: URL) -> [TransactionStruct] {
        var transactions: [TransactionStruct] = []
        
        var accountTemp: String = ""
        
        print("Starting BofS CSV parse: \(fileURL.path)")
        
        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            guard let headers = rows.first else { return [] }
            
            let matcher = CategoryMatcher(context: PersistenceController.shared.container.viewContext)
            
            for row in rows.dropFirst() {
                print( row.count, headers.count)
                guard row.count == headers.count else { continue }
                
                var tx = TransactionStruct()
                
                for (index, header) in headers.enumerated() {
                    let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    switch header.lowercased() {
                    case "transaction date":
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yyyy"
                        tx.transactionDate = formatter.date(from: value)
                        
                    case "transaction type":
                        tx.explanation = value
                        
                    case "sort code":
                        accountTemp = value
                        
                    case "account number":
                        accountTemp +=  " " + value
                        
                    case "transaction description":
                        tx.payee = value
                        tx.category = matcher.matchCategory(for: value)
                        
                    case "debit amount":
                        if let debit = Decimal(string: value.replacingOccurrences(of: ",", with: "")), debit > 0 {
                            tx.txAmount = debit
                            tx.debitCredit = .DR
                        }
                        
                    case "credit amount":
                        if let credit = Decimal(string: value.replacingOccurrences(of: ",", with: "")), credit > 0 {
                            tx.txAmount = credit
                            tx.debitCredit = .CR
                        }
                        
                    case "balance":
                        break   // Ignore
                        
                    default:
                        break
                    }
                }
                
                tx.paymentMethod = paymentMethod
                tx.accountNumber = accountTemp
                // Default currency is GBP
                tx.currency = .GBP
                tx.exchangeRate = 1
                
                transactions.append(tx)
            }
            
        } catch {
            print("Failed to read BofS CSV: \(error)")
        }
        
        return transactions
    }
    
}
