//
//  TransactionExtensions.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import Foundation
import CoreData

/*
 @NSManaged public var accountNumber: String?
 @NSManaged public var address: String?
 @NSManaged public var categoryCD: Int32
 @NSManaged public var closed: Bool
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

// MARK: --- CentsConvertible conformance
extension Transaction: CentsConvertible {}

// MARK: --- TransactionValidatable conformance
extension Transaction: TransactionValidatable {}

// MARK: --- Static Helpers
extension Transaction {
    
    // Static shared formatter
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short   // change to .medium or .long if desired
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: --- Computed properties for Transaction
extension Transaction {
    
    var category: Category {
        get { Category(rawValue: categoryCD) ?? .unknown }
        set { categoryCD = newValue.rawValue }
    }

    var commissionAmount: Decimal {
        get { Decimal(commissionAmountCD) / 100.0 }
        set { commissionAmountCD = decimalToCents(newValue) }
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
        get {
            let rate = Decimal(exchangeRateCD) / 100
            return rate == 0 ? 1 : rate   // avoid divide-by-zero → force 1
        }
        set {
            exchangeRateCD = decimalToCents(newValue == 0 ? 1 : newValue)
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
        get { Decimal(splitAmountCD) / 100 }
        set { splitAmountCD = decimalToCents(newValue) }
    }

    var splitAmountInGBP: Decimal {
        assert(exchangeRate != 0)
        let converted = splitAmount / exchangeRate   // convert to GBP
        let value = converted + commissionAmount     // add commission
        if value.isNaN { return Decimal(0) }
        return value
    }

    var splitCategory: Category {
        get { Category(rawValue: splitCategoryCD) ?? .unknown }
        set { splitCategoryCD = newValue.rawValue }
    }

    var splitRemainderAmount: Decimal {
        get { Decimal(txAmountCD - splitAmountCD) / 100 }
    }

    var splitRemainderAmountInGBP: Decimal {
        assert(exchangeRate != 0)
        let value = splitRemainderAmount / exchangeRate
        if value.isNaN { return Decimal(0) }
        return value
    }

    var splitRemainderCategory: Category {
        get { Category(rawValue: categoryCD) ?? .unknown }
    }

    var txAmount: Decimal {
        get { Decimal(txAmountCD) / 100 }
        set { txAmountCD = decimalToCents(newValue) }
    }
    
    var txAmountInGBP: Decimal {
        assert(exchangeRate != 0)
        let value = txAmount / exchangeRate
        if value.isNaN { return Decimal(0) }
        return value
    }

    var totalAmountInGBP: Decimal {
        let total = splitAmountInGBP + splitRemainderAmountInGBP
        var roundedTotal = Decimal()
        var totalCopy = total
        NSDecimalRound(&roundedTotal, &totalCopy, 2, .plain)
        return roundedTotal
    }
}

// MARK: --- Extensions to make Table Viewing much simpler
extension Transaction {
    
    func commissionAmountAsString() -> String? {
        let amount = NSDecimalNumber(decimal: commissionAmount)
        return String(format: "%.2f", amount.doubleValue)
    }

    func exchangeRateAsString() -> String? {
        let fx = NSDecimalNumber(decimal: exchangeRate)
        switch currency {
        case .GBP:
            return String(format: "%.2f", fx.doubleValue)
        case .JPY:
            return String(format: "%.0f", fx.doubleValue)
        default:
            return String(format: "%.2f", fx.doubleValue)
        }
    }

    func splitRemainderAsString() -> String? {
        let amountNumber = NSDecimalNumber(decimal: splitRemainderAmount)
        switch currency {
        case .JPY:
            return String(format: "%.0f", amountNumber.doubleValue)
        default:
            return String(format: "%.2f", amountNumber.doubleValue)
        }
    }

    func timestampAsString() -> String? {
        guard let date = timestamp else { return nil }
        return Transaction.dateFormatter.string(from: date)
    }

    func transactionDateAsString() -> String? {
        guard let date = transactionDate else { return nil }
        return Transaction.dateFormatter.string(from: date)
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

    func splitAmountAsString() -> String? {
        let amountNumber = NSDecimalNumber(decimal: splitAmount)
        switch currency {
        case .JPY: return String(format: "%.0f", amountNumber.doubleValue)
        default: return String(format: "%.2f", amountNumber.doubleValue)
        }
    }
    
}

// MARK: --- GenerateRandomTransactions
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
            
            let randomInterval = TimeInterval.random(in: 0...(endDate.timeIntervalSince(startDate)))
            transaction.transactionDate = startDate.addingTimeInterval(randomInterval)
            
            transaction.categoryCD = Int32(categories.randomElement()!)
            transaction.payerCD = Int32(payers.randomElement()!)
            transaction.payee = payees.randomElement()
            transaction.explanation = explanations.randomElement()
            
            transaction.paymentMethodCD = paymentMethod.rawValue
            transaction.currencyCD = currency.rawValue
            
            let isCredit = Bool.random()
            transaction.debitCreditCD = isCredit ? 2 : 1
            
            let amount = Int32.random(in: 10_00...100_00)
            transaction.txAmountCD = isCredit ? amount : -amount
            
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

// MARK: --- Helpers for TransactionStruct matching
extension Transaction {
    
    static func hasMultipleMatches(for temp: TransactionStruct, in context: NSManagedObjectContext) -> Bool {
        return matchCount(for: temp, in: context) > 1
    }
    
    static func matchCount(for temp: TransactionStruct, in context: NSManagedObjectContext) -> Int {
        guard let date = temp.transactionDate else { return 0 }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: date)!
        let endDate   = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        let txAmountCDValue: Int32 = {
            let value = temp.txAmount * 100
            var result = Decimal()
            var copy = value
            NSDecimalRound(&result, &copy, 0, .plain)
            return NSDecimalNumber(decimal: result).int32Value
        }()
        
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
    
//    func comparableFieldsRepresentation() -> String {
//        
//        var components: [String] = []
//        let mirror = Mirror(reflecting: self)
//        print("Mirror children:", Mirror(reflecting: self).children.map { $0.label ?? "nil" })
//        for child in mirror.children {
//            guard let label = child.label else { continue }
//            if label == "id" || label == "timestamp" { continue }
//            let value = String(describing: child.value)
//            components.append("\(label)=\(value)")
//        }
//        return components.joined(separator: "|")
//    }
}

extension Transaction {
    /// Builds a reproducible comparable string from MergeField definitions.
    /// Skips volatile fields like `timestamp`.
    func comparableFieldsRepresentation() -> String {
        var components: [String] = []

        for field in MergeField.allCases {
            // Skip fields that shouldn't affect equality
            if field == .timestamp { continue }

            guard let info = MergeField.all[field] else { continue }

            let value = info.getter(self)
            if !value.isEmpty {
                components.append("\(field.rawValue)=\(value)")
            }
        }

        // Sort so order is deterministic
        components.sort()
        return components.joined(separator: "|")
    }
}
