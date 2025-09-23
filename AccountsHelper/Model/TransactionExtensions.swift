//
//  CoredataExtensions.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import Foundation
import CoreData

extension Transaction {
    
    public var commissionAmount: Decimal {
        get { Decimal(commissionAmountCD) / 100.0 }
        set {
            // Multiply by 100 to store cents
            var scaled = newValue * Decimal(100)
            var rounded = Decimal()
            NSDecimalRound(&rounded, &scaled, 0, .plain)
            commissionAmountCD = Int32(truncating: NSDecimalNumber(decimal: rounded))
        }
    }
}

// MARK: --- Computed properties for Transaction
extension Transaction {
    var category: Category {
        get { Category(rawValue: categoryCD) ?? .unknown }
        set { categoryCD = newValue.rawValue }
    }

    var currency: Currency {
        get { Currency(rawValue: currencyCD) ?? .unknown }
        set { currencyCD = newValue.rawValue }
    }

    var debitCredit: DebitCredit {
        get { DebitCredit(rawValue: debitCreditCD) ?? .unknown }
        set { debitCreditCD = newValue.rawValue }
    }

    var exchangeRate: Decimal {
        get { Decimal(exchangeRateCD)/100 }
        set {
            // Multiply by 100 to store cents
            var scaled = newValue * Decimal(100)
            var rounded = Decimal()
            NSDecimalRound(&rounded, &scaled, 0, .plain)
            exchangeRateCD = Int32(truncating: NSDecimalNumber(decimal: rounded))
        }
    }

    var payer: Payer {
        get { Payer(rawValue: payerCD) ?? .unknown }
        set { payerCD = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodCD) ?? .unknown }
        set { paymentMethodCD = newValue.rawValue }
    }

    var splitAmount: Decimal {
        get { Decimal(splitAmountCD)/100 }
        set {
            // Multiply by 100 to store cents
            var scaled = newValue * Decimal(100)
            var rounded = Decimal()
            NSDecimalRound(&rounded, &scaled, 0, .plain)
            splitAmountCD = Int32(truncating: NSDecimalNumber(decimal: rounded))
            // Ensure the two split amounts always sum to the transaction amount
//            splitAmount2CD = txAmountCD - splitAmount1CD
        }
    }

    var splitCategory: Category {
        get { Category(rawValue: splitCategoryCD) ?? .unknown }
        set { splitCategoryCD = newValue.rawValue }
    }

    // We only keeps the txAmount and the first split value. The remaining split value is computed.
    var splitRemainderAmount: Decimal {
        get { Decimal(txAmountCD - splitAmountCD)/100 }
        set { }
    }

    // Remainder Category is a new category entered for the calculated remainder
    var splitRemainderCategory: Category {
        get { Category(rawValue: categoryCD) ?? .unknown }
        set { }
    }

    var txAmount: Decimal {
        get { Decimal(txAmountCD)/100 }
        set {
            // Multiply by 100 to store cents
            var scaled = newValue * Decimal(100)
            var rounded = Decimal()
            NSDecimalRound(&rounded, &scaled, 0, .plain)
            txAmountCD = Int32(truncating: NSDecimalNumber(decimal: rounded))
        }
    }
}

// MARK: --- Estensions to make Table Viewing much simpler
extension Transaction {
    
    func transactionDateAsString() -> String? {
        guard let date = transactionDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short   // or .medium / .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func txAmountAsString() -> String? {
        guard let amount = txAmount as? NSDecimalNumber else { return nil }
        return String(format: "%.2f", amount.doubleValue)
    }
    
    func exchangeRateAsString() -> String? {
        guard let fx = exchangeRate as? NSDecimalNumber else { return nil }
        switch currency {
            
        case .GBP:
            return ""

        case .JPY:
            return String(format: "%.0f", fx.doubleValue)
            
        default:
            return String(format: "%.2f", fx.doubleValue)
        }

    }
    
    func splitRemainderAsString() -> String? {
        guard let amount = splitRemainderAmount as? NSDecimalNumber else { return nil }
        return String(format: "%.2f", amount.doubleValue)
    }
}



// MARK: --- GenerateRandomTransactions
// Generates 10 random Transaction instances in the given context
extension Transaction {
    static func generateRandomTransactions(in context: NSManagedObjectContext) -> [Transaction] {
        var transactions: [Transaction] = []
        
        for _ in 0..<10 {
            let transaction = Transaction(context: context)
            
            transaction.timestamp = Date()
            
            // Random Int32 values within some reasonable ranges
            transaction.categoryCD = Int32.random(in: 1...27)
            transaction.currencyCD = Int32.random(in: 1...4)
            transaction.debitCreditCD = Int32.random(in: 1...2)

            switch transaction.currency {
            case .GBP:
                transaction.exchangeRateCD = 100
            case .USD:
                transaction.exchangeRateCD = Int32.random(in: 120...150)
            case .JPY:
                transaction.exchangeRateCD = Int32.random(in: 15000...21000)
            case .EUR:
                transaction.exchangeRateCD = Int32.random(in: 120...150)
            case .unknown:
                transaction.exchangeRateCD = Int32(0)
            }
            
            transaction.payerCD = Int32.random(in: 1...2)
            transaction.paymentMethodCD = Int32.random(in: 1...4)
            transaction.splitAmountCD = Int32.random(in: 0...1000)
            transaction.splitCategoryCD = Int32.random(in: 1...27)
            transaction.txAmountCD = Int32.random(in: 0...10000)
            
            // Random explanation and payee strings
            transaction.explanation = ["For busiiness trip", "Kuroki paid", "Old transaction repeated", "Ref 0002", "", ""].randomElement()
            transaction.payee = ["Tesco", "SPAR", "Lawson", "Komedia", "Ayhadio"].randomElement()
            
            // Random dates within the last year
            let now = Date()
            let randomInterval = TimeInterval.random(in: -365*24*60*60...0)
//            transaction.timestamp = now.addingTimeInterval(randomInterval)
            transaction.transactionDate = now.addingTimeInterval(randomInterval)
            
            transactions.append(transaction)
        }
        
        // Save context if needed
        try? context.save()
        
        return transactions
    }
}


