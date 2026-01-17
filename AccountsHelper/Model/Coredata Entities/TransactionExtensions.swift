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

// MARK: --- Static Calculators
extension   Transaction {
    
    static func totalTxAmount<T: Sequence>(for transactions: T) -> Decimal where T.Element == Transaction {
        transactions.reduce(0) { $0 + $1.txAmount }
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
        get {
            let rate = Decimal(exchangeRateCD) / 10000.0
            return rate == 0 ? 1 : rate
        }
        set {
            // 1. Ensure non-zero safe value
            let safeValue = (newValue == 0) ? Decimal(1) : newValue

            // 2. Scale
            let scaled = safeValue * Decimal(10_000)

            // 3. Round to integer (nearest)
            var rounded = Decimal()
            var copy = scaled
            NSDecimalRound(&rounded, &copy, 0, .plain) // 0 fractional digits

            // 4. Convert to Int32 safely (clamp to Int32 range)
            let nsNumber = NSDecimalNumber(decimal: rounded)
            let int64Value = nsNumber.int64Value
            let clamped = min(Int64(Int32.max), max(Int64(Int32.min), int64Value))
            exchangeRateCD = Int32(clamped)
            print("ExchangeRateCD Setter: \(exchangeRateCD)")
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

    var splitCategory: Category {
        get { Category(rawValue: splitCategoryCD) ?? .unknown }
        set { splitCategoryCD = newValue.rawValue }
    }
    

    var splitRemainderCategory: Category {
        get { Category(rawValue: categoryCD) ?? .unknown }
    }
    
    // Raw Amounts
    var commissionAmount: Decimal {
        get { Decimal(commissionAmountCD) / 100.0 }
        set { commissionAmountCD = decimalToCents(newValue) }
    }
    
    var txAmount: Decimal {
        get { Decimal(txAmountCD) / 100 }
        set {
            txAmountCD = decimalToCents(newValue)
            print("txAmountCD Setter: \(txAmountCD) from newValue: \(newValue)")
        }
    }

    var splitAmount: Decimal {
        get { Decimal(splitAmountCD) / 100 }
        set { splitAmountCD = decimalToCents(newValue) }
    }

    // Computed Amounts
    var splitAmountInGBP: Decimal {
        assert(exchangeRate != 0)
        let converted = splitAmount / exchangeRate   // convert to GBP
        let value = converted + commissionAmount     // add commission
        if value.isNaN { return Decimal(0) }
        return value
    }

    var splitRemainderAmount: Decimal {
        get { txAmount - splitAmount }
    }

    var splitRemainderAmountInGBP: Decimal {
        assert(exchangeRate != 0)
        let value = splitRemainderAmount / exchangeRate
        if value.isNaN { return Decimal(0) }
        return value
    }
    
    var txAmountInGBP: Decimal {
        assert(exchangeRate != 0)
        let value = txAmount / exchangeRate + commissionAmount
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

// MARK: --- Extensions to return amounts as Strings for easier incorporation into Views and Reports
extension Transaction {
    
    // MARK: --- AnyAmountAsString
    // Moved to AmountFormatter
    
    // MARK: --- CommissionAmountAsString
    // Commission amount always in GBP
    func commissionAmountAsString( withSymbol: ShowCurrencySymbolsEnum = .always ) -> String? {
        let amount = NSDecimalNumber(decimal: commissionAmount)
        if amount == 0 { return gDefaultZeroAmountRepresentation }
        if withSymbol.show(currency: currency) {
            return amount.decimalValue.formattedAsCurrency(currency)
        } else {
            return String(format: "%.2f", amount.doubleValue)
        }
    }

    // MARK: --- SxchangeRateAsStringLong
    func exchangeRateAsStringLong() -> String? {
        let fx = NSDecimalNumber(decimal: exchangeRate)
        if fx == 0 || fx == 1 { return gDefaultZeroAmountRepresentation }
        switch currency {
        case .GBP:
            return String(format: "%.4f", fx.doubleValue)
        case .JPY:
            return String(format: "%.4f", fx.doubleValue)
        default:
            return String(format: "%.4f", fx.doubleValue)
        }
    }
    
    // MARK: --- ExchangeRateAsString
    func exchangeRateAsString() -> String? {
        let fx = NSDecimalNumber(decimal: exchangeRate)
        if fx == 0 || fx == 1 { return gDefaultZeroAmountRepresentation }
        switch currency {
        case .GBP:
            return String(format: "%.2f", fx.doubleValue)
        case .JPY:
            return String(format: "%.0f", fx.doubleValue)
        default:
            return String(format: "%.2f", fx.doubleValue)
        }
    }

    // MARK: --- SplitRemainderAsString
    func splitRemainderAsString( withSymbol: ShowCurrencySymbolsEnum = .always ) -> String? {
        let amount = NSDecimalNumber(decimal: splitRemainderAmount)
        if amount == 0 { return gDefaultZeroAmountRepresentation }
        switch currency {
        case .JPY:
            if withSymbol.show(currency: currency) {
                return amount.decimalValue.formattedAsCurrency(currency)
            } else {
                return String(format: "%.0f", amount.doubleValue)
            }

        default:
            if withSymbol.show(currency: currency) {
                return amount.decimalValue.formattedAsCurrency(currency)
            } else {
                return String(format: "%.2f", amount.doubleValue)
            }
        }
    }

    // MARK: --- TxAmountAsString
    func txAmountAsString( withSymbol: ShowCurrencySymbolsEnum = .always ) -> String {
        let amount = NSDecimalNumber(decimal: txAmount)
        if amount == 0 { return "" }
        switch currency {
        case .JPY:
            if withSymbol.show(currency: currency) {
                return amount.decimalValue.formattedAsCurrency(currency)
            } else {
                return String(format: "%.0f", amount.doubleValue)
            }

        default:
            if withSymbol.show(currency: currency) {
                return amount.decimalValue.formattedAsCurrency(currency)
            } else {
                return String(format: "%.2f", amount.doubleValue)
            }
        }
    }
    
    // MARK: --- TxAmountDualCurrencyAsString
    func txAmountDualCurrencyAsString( withSymbol: ShowCurrencySymbolsEnum = .always ) -> String {
        var s1 = txAmountAsString(withSymbol: withSymbol)
        if currency == .GBP { return s1 }
        if withSymbol == .never { s1 = "" }
        if s1 != "" { s1 += "\n" }
        let s2 = AmountFormatter.anyAmountAsString( amount: txAmountInGBP, currency: .GBP, withSymbol: withSymbol )
#if os(macOS)
        return "\(s1)\(s2)"
#else
//            return wip + " " + transaction.totalAmountInGBP.formattedAsCurrency( .GBP )
        return "\(s1)"
#endif
    }

    // MARK: --- SplitAmountAsString
    func splitAmountAsString( withSymbol: ShowCurrencySymbolsEnum = .always ) -> String {
        let amount = NSDecimalNumber(decimal: splitAmount)
        if amount == 0 { return gDefaultZeroAmountRepresentation }
        switch currency {
        case .JPY:
            if withSymbol.show(currency: currency) {
                return amount.decimalValue.formattedAsCurrency(currency)
            } else {
                return String(format: "%.0f", amount.doubleValue)
            }

        default:
            if withSymbol.show(currency: currency) {
                return amount.decimalValue.formattedAsCurrency(currency)
            } else {
                return String(format: "%.2f", amount.doubleValue)
            }
        }
    }
    
    // MARK: --- SplitAmountAndCategoryAsString
    func splitAmountAndCategoryAsString( withSymbol: ShowCurrencySymbolsEnum = .always ) -> String {
        guard splitAmount != 0 else { return gDefaultZeroAmountRepresentation }
        let s1 = splitCategory.description
        let s2 = splitAmountAsString(withSymbol: withSymbol)
        return "\(s1) - \(s2)"
    }

    // MARK: --- TimestampAsString
    func timestampAsString() -> String? {
        guard let date = timestamp else { return nil }
        return Transaction.dateFormatter.string(from: date)
    }

    // MARK: --- TransactionDateAsString
    func transactionDateAsString() -> String? {
        guard let date = transactionDate else { return nil }
        return Transaction.dateFormatter.string(from: date)
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
