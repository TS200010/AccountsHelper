//
//  AMEXCSVImporter.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 21/09/2025.
//


import Foundation
import CoreData

class AMEXCSVImporter {
    
    static func importCSVToCoreData(fileURL: URL, context: NSManagedObjectContext) {
        
        let matcher = CategoryMatcher(context: context)
        
        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = parseCSV(csvData: csvData)
            
            guard let headers = rows.first else { return }
            
            for row in rows.dropFirst() {
                
                // Temps to build an address
                var addressTemp: String = ""
                var postcodeTemp: String = ""
                var townCityTemp: String = ""
                var countryTemp: String = ""
                
                // Temps to process amount and extendedDetails correctly one all have been read
                var txAmountTemp: Decimal = Decimal(0)
//                var extendedDetailsTemp: String = ""
                var txAmountParsedTemp: Decimal = Decimal(0)
                var exchangeRateParsedTemp: Decimal = Decimal(0)
                var commissionAmountParsedTemp: Decimal = Decimal(0)
                var currencyParsedTemp: Currency = .unknown
                
                guard row.count == headers.count else {
                    print("Malformed row \(row)\n")
                    continue
                } // skip malformed rows
                
                let transaction = Transaction(context: context)
                
                // We need to save txAmount and extendedDetails for processing after
                // ... all the fields have been processed
                for (index, header) in headers.enumerated() {
                    let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    transaction.paymentMethod = .AMEX
                    
                    switch header.lowercased() {
                    case "date":
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yyyy"
                        transaction.transactionDate = formatter.date(from: value)
                        
//                    case "description":
//                        transaction.payee = value
                        
                    case "description":
                        transaction.payee = value
                        
                        // Automatically match a category
                        let matchedCategory = matcher.matchCategory(for: value)
                        if matchedCategory != .unknown {
                            transaction.category = matchedCategory
                        } else {
                            transaction.category = .unknown
                        }
                        
                    case "card member":
                        transaction.payer = Payer( value )
                        
                    case "account #":
                        transaction.accountNumber = value
                        
                    case "amount":
                        txAmountTemp  = Decimal(string: value.replacingOccurrences(of: ",", with: "")) ?? Decimal(999)
                        
                    case "extended details":
                        transaction.extendedDetails = value
                        let parsed = parseExtendedDetails(value)
                        print(parsed)
                        txAmountParsedTemp = parsed.foreignSpendAmount ?? Decimal(0)
                        commissionAmountParsedTemp = parsed.commissionAmount ?? Decimal(0)
                        exchangeRateParsedTemp = parsed.exchangeRate ?? Decimal(0)
                        currencyParsedTemp = parsed.foreignCurrency ?? .unknown
                        
                    case "appears on your statement as":
                        // Ignore this field
                        break
//                        transaction.appearsOnStatementAs = value
                        
                    case "address":
                        addressTemp = value
                        
                    case "town/city":
                        townCityTemp = value
                        
                    case "postcode":
                        postcodeTemp = value
                        
                    case "country":
                        countryTemp = value

                    case "reference":
                        transaction.reference = value
                    case "category":
                        // Ignore this field
                        break
                        //                        transaction.category = value
                    default:
                        break
                    }
                }
                // Timestamp
                transaction.timestamp = Date()
                
                // Now prcoess fields we have had to wait for
                // Address
                transaction.address = addressTemp + ", " + townCityTemp + ", "  + postcodeTemp + ", " + countryTemp
                
                // Amount and Exchange Rate fields
                if currencyParsedTemp == .GBP ||  currencyParsedTemp == .unknown {
                    transaction.currency = .GBP
                    transaction.exchangeRate = Decimal(1)
                    transaction.txAmount = txAmountTemp
                } else {
                    // This is a foreign currency transaction, we store the amount in foreign
                    // ... currency so that we can later reconcile it to the receipt.
                    // ... We add the commision when we retrieve a txAmount in GBP
                    transaction.txAmount = txAmountParsedTemp
                    transaction.currency = currencyParsedTemp
                    transaction.exchangeRate = exchangeRateParsedTemp
                    transaction.commissionAmount = commissionAmountParsedTemp
                }
                transaction.debitCredit = txAmountTemp >= 0 ? .DR : .CR
            }
            
            matcher.reapplyMappingsToUnknownTransactions()
            
            try context.save()
            print("CSV import successful! Imported \(rows.count - 1) transactions.")
            
        } catch {
            print("Failed to read CSV file: \(error)")
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
    

