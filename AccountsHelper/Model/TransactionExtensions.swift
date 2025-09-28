//
//  TransactionExtensions.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import Foundation
import CoreData

/*
 @NSManaged public var accountingPeriod: String?
 @NSManaged public var accountNumber: String?
 @NSManaged public var address: String?
 @NSManaged public var categoryCD: Int32
 @NSManaged public var commissionAmountCD: Int32
 @NSManaged public var currencyCD: Int32
 @NSManaged public var debitCreditCD: Int32
 @NSManaged public var exchangeRateCD: Int32
 @NSManaged public var explanation: String?
 @NSManaged public var extendedDetails: String?
 @NSManaged public var payee: String?
 @NSManaged public var payerCD: Int32
 @NSManaged public var paymentMethodCD: Int32
 @NSManaged public var reference: String?
 @NSManaged public var splitAmountCD: Int32
 @NSManaged public var splitCategoryCD: Int32
 @NSManaged public var timestamp: Date?
 @NSManaged public var transactionDate: Date?
 @NSManaged public var txAmountCD: Int32
 */

/*
 | --------------------------- | --------------- | -------------------------------------------------------- |
 | Property / Method           | Type            | Description                                              |
 | --------------------------- | --------------- | -------------------------------------------------------- |
 | `txAmount`                  | `Decimal`       | Transaction amount                                       |
 | `splitAmount`               | `Decimal`       | First split amount                                       |
 | `splitRemainderAmount`      | `Decimal`       | Computed remainder = `txAmount - splitAmount`            |
 | `commissionAmount`          | `Decimal`       | Commission amount                                        |
 | `exchangeRate`              | `Decimal`       | Exchange rate                                            |
 | `totalInGBP`                | `Decimal`       | `(txAmount * exchangeRate) + commissionAmount` (rounded) |
 | --------------------------- | --------------- | -------------------------------------------------------- |
 | `category`                  | `Category`      | Transaction category                                     |
 | `splitCategory`             | `Category`      | Split transaction category                               |
 | `splitRemainderCategory`    | `Category`      | Category for the remainder (same as main category)       |
 | --------------------------- | --------------- | -------------------------------------------------------- |
 | `currency`                  | `Currency`      | Transaction currency                                     |
 | `debitCredit`               | `DebitCredit`   | Debit or credit type                                     |
 | `payer`                     | `Payer`         | Who paid the transaction                                 |
 | `paymentMethod`             | `PaymentMethod` | Payment method used                                      |
 | --------------------------- | --------------- | -------------------------------------------------------- |
 | `txAmountAsString()`        | `String?`       | Formatted transaction amount                             |
 | `splitRemainderAsString()`  | `String?`       | Formatted remainder amount                               |
 | `exchangeRateAsString()`    | `String?`       | Formatted exchange rate                                  |
 | `transactionDateAsString()` | `String?`       | Formatted transaction date                               |
 | --------------------------- | --------------- | -------------------------------------------------------- |
*/

// MARK: --- CentsConvertible conformance
extension Transaction: CentsConvertible {}

// MARK: --- TransactionValidatable conformance
extension Transaction: TransactionValidatable {}

// MARK: --- Computed properties for Transaction
extension Transaction {
    
//    private func decimalToCents(_ value: Decimal) -> Int32 {
//        var scaled = value * 100
//        var rounded = Decimal()
//        NSDecimalRound(&rounded, &scaled, 0, .plain)
//        return Int32(truncating: NSDecimalNumber(decimal: rounded))
//    }
    
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
        get { Decimal(exchangeRateCD) / 100 }
        set { exchangeRateCD = decimalToCents(newValue) }
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
        get { Decimal(splitAmountCD) / 100 }
        set { splitAmountCD = decimalToCents(newValue) }
    }

    // Split Category is a new category entered
    var splitCategory: Category {
        get { Category(rawValue: splitCategoryCD) ?? .unknown }
        set { splitCategoryCD = newValue.rawValue }
    }

    // We only keeps the txAmount and the first split value. The remaining split value is computed.
    var splitRemainderAmount: Decimal {
        get { Decimal(txAmountCD - splitAmountCD)/100 }
    }

    // Remainder Category is the original category of txAmount
    var splitRemainderCategory: Category {
        get { Category(rawValue: categoryCD) ?? .unknown }
    }

    var txAmount: Decimal {
        get { Decimal(txAmountCD) / 100 }
        set { txAmountCD = decimalToCents(newValue) }
    }
    
    var commissionAmount: Decimal {
        get { Decimal(commissionAmountCD) / 100.0 }
        set { commissionAmountCD = decimalToCents(newValue) }
    }

    var totalInGBP: Decimal {
        let converted = txAmount / exchangeRate
        let total = converted + commissionAmount
        var roundedTotal = Decimal()
        var totalCopy = total
        NSDecimalRound(&roundedTotal, &totalCopy, 2, .plain)
        return roundedTotal
    }
}


// MARK: --- Estensions to make Table Viewing much simpler
extension Transaction {
    
    func transactionDateAsString() -> String? {
        guard let date = transactionDate else { return nil }
        return Transaction.dateFormatter.string(from: date)
    }
    
    func timestampAsString() -> String? {
        guard let date = timestamp else { return nil }
        return Transaction.dateFormatter.string(from: date)
    }

    // Static shared formatter
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short   // change to .medium or .long if desired
        formatter.timeStyle = .none
        return formatter
    }()
    
//    func txAmountAsStringOld() -> String? {
//        let amount = NSDecimalNumber(decimal: txAmount)
//        return String(format: "%.2f", amount.doubleValue)
//    }
    
    func commissionAmountAsString() -> String? {
        let amount = NSDecimalNumber(decimal: commissionAmount)
        return String(format: "%.2f", amount.doubleValue)
    }
    
    func txAmountAsString() -> String? {
        let amountNumber = NSDecimalNumber(decimal: txAmount)

        switch currency {
        case .JPY:
            return String(format: "%.0f", amountNumber.doubleValue)
        default:
            return String(format: "%.2f", amountNumber.doubleValue)
        }
    }
    
    func exchangeRateAsString() -> String? {
//        guard let fx = exchangeRate as? NSDecimalNumber else { return nil }
//        
//        switch currency {
//            
//        case .GBP:
//            return ""
//
//        case .JPY:
//            return String(format: "%.0f", fx.doubleValue)
//            
//        default:
//            return String(format: "%.2f", fx.doubleValue)
//        }
        let fx = NSDecimalNumber(decimal: exchangeRate)
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
//        guard let amount = splitRemainderAmount as? NSDecimalNumber else { return nil }
//        return String(format: "%.2f", amount.doubleValue)
        let amountNumber = NSDecimalNumber(decimal: splitRemainderAmount)

        switch currency {
        case .JPY:
            return String(format: "%.0f", amountNumber.doubleValue)
        default:
            return String(format: "%.2f", amountNumber.doubleValue)
        }
    }
}



// MARK: --- GenerateRandomTransactions
// Generates 10 random Transaction instances in the given context
extension Transaction {
    
    static func generateRandomTransactions(
        for paymentMethod: PaymentMethod,
        currency: Currency,
        startDate: Date,
        endDate: Date,
        count: Int = 20,
        in context: NSManagedObjectContext
    ) -> [Transaction] {
        
        var transactions: [Transaction] = []
        let categories = Array(1...27)
        let payers = Array(1...5)
        let payees = ["Tesco", "SPAR", "Lawson", "Komedia", "Ayhadio"]
        let explanations = ["Business trip", "Client payment", "Old transaction repeated", "Ref 0002", "", ""]
        
        for _ in 0..<count {
            let transaction = Transaction(context: context)
            
            // Random transaction date within the range
            let randomInterval = TimeInterval.random(in: 0...(endDate.timeIntervalSince(startDate)))
            transaction.transactionDate = startDate.addingTimeInterval(randomInterval)
            
            transaction.categoryCD = Int32(categories.randomElement()!)
            transaction.payerCD = Int32(payers.randomElement()!)
            transaction.payee = payees.randomElement()
            transaction.explanation = explanations.randomElement()
            
            // Assign payment method and currency
            transaction.paymentMethodCD = paymentMethod.rawValue
            transaction.currencyCD = currency.rawValue
            
            // Assign a debit or credit
            let isCredit = Bool.random()
            transaction.debitCreditCD = isCredit ? 2 : 1
            
            // Random amount between 10 and 1000 units
            let amount = Int32.random(in: 10_00...100_00) // in cents
            transaction.txAmountCD = isCredit ? amount : -amount
            
            // Set exchange rate (simple realistic values)
            switch currency {
            case .GBP: transaction.exchangeRateCD = 100
            case .USD: transaction.exchangeRateCD = Int32.random(in: 120...150)
            case .JPY: transaction.exchangeRateCD = Int32.random(in: 15_000...21_000)
            case .EUR: transaction.exchangeRateCD = Int32.random(in: 120...150)
            case .unknown: transaction.exchangeRateCD = 0
            }
            
            transactions.append(transaction)
        }
        
        try? context.save()
        return transactions
    }
}

extension Transaction {
    /// Creates a new Core Data Transaction from a TransactionStruct
    static func create(from temp: TransactionStruct, in context: NSManagedObjectContext) -> Transaction {
        let transaction = Transaction(context: context)
        
        // Simple String properties
        transaction.accountNumber = temp.accountNumber
        transaction.address = temp.address
        transaction.explanation = temp.explanation
        transaction.extendedDetails = temp.extendedDetails
        transaction.payee = temp.payee
        transaction.reference = temp.reference
        transaction.timestamp = temp.timestamp
        transaction.transactionDate = temp.transactionDate
        
        // Enum-backed properties
        transaction.categoryCD = temp.category.rawValue
        transaction.splitCategoryCD = temp.splitCategory.rawValue
        transaction.currencyCD = temp.currency.rawValue
        transaction.debitCreditCD = temp.debitCredit.rawValue
        transaction.payerCD = temp.payer.rawValue
        transaction.paymentMethodCD = temp.paymentMethod.rawValue
        
        // Amounts and rates (convert Decimal → Int32 storage)
        transaction.txAmount = temp.txAmount
        transaction.splitAmount = temp.splitAmount
        transaction.exchangeRate = temp.exchangeRate
        transaction.commissionAmount = temp.commissionAmount
        
        return transaction
    }
}

extension Transaction {
    /// Returns the number of matches for a TransactionStruct in the database, including paymentMethod
    static func matchCount(for temp: TransactionStruct, in context: NSManagedObjectContext) -> Int {
        guard let date = temp.transactionDate else { return 0 }

        // Date range: 7 days before → 1 day after
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: date)!
        let endDate   = Calendar.current.date(byAdding: .day, value: 1, to: date)!

        // Convert Decimal txAmount to Int32 for predicate
        let txAmountCDValue = Int32(truncating: NSDecimalNumber(decimal: temp.txAmount * 100))

        // Build fetch request
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "txAmountCD == %d", txAmountCDValue),
            NSPredicate(format: "currencyCD == %d", temp.currency.rawValue),
            NSPredicate(format: "paymentMethodCD == %d", temp.paymentMethod.rawValue),
            NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", startDate as NSDate, endDate as NSDate)
        ])

        do {
            return try context.count(for: request)
        } catch {
            print("Error counting matching transactions: \(error)")
            return 0
        }
    }

    /// Convenience: checks if there is more than one match
    static func hasMultipleMatches(for temp: TransactionStruct, in context: NSManagedObjectContext) -> Bool {
        return matchCount(for: temp, in: context) > 1
    }
}




