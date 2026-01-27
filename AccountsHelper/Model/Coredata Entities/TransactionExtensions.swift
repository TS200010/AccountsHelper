//
//  TransactionExtensions.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import Foundation
import CoreData

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
//            print("ExchangeRateCD Setter: \(exchangeRateCD)")
        }
    }

    var payer: Payer {
        get { Payer(rawValue: payerCD) ?? .unknown }
        set { payerCD = newValue.rawValue }
    }

    var account: ReconcilableAccounts {
        get { ReconcilableAccounts(rawValue: accountCD) ?? .unknown }
        set { accountCD = newValue.rawValue }
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
//            print("txAmountCD Setter: \(txAmountCD) from newValue: \(newValue)")
        }
    }

    var splitAmount: Decimal {
        get { Decimal(splitAmountCD) / 100 }
        set { splitAmountCD = decimalToCents(newValue) }
    }
    
    // Computed Amounts
    var splitRemainderAmount: Decimal {
        get { txAmount - splitAmount }
    }

    // Raw Amounts in GBP
    var splitAmountInGBP: Decimal {
        assert(exchangeRate != 0)
        let converted = splitAmount / exchangeRate   // convert to GBP
//        let value = converted + commissionAmount     // add commission
        if converted.isNaN { return Decimal(0) }
        return converted
    }
    
    var txAmountInGBP: Decimal {
        assert(exchangeRate != 0)
        let value = txAmount / exchangeRate
//        let value = txAmount / exchangeRate + commissionAmount
        if value.isNaN { return Decimal(0) }
        return value
    }

    // Computed Amounts in GBP
    var splitRemainderAmountInGBP: Decimal {
        assert(exchangeRate != 0)
        let converted = splitRemainderAmount / exchangeRate
        let value = converted// + commissionAmount     // add commission
        if value.isNaN { return Decimal(0) }
        return value
    }

    var totalAmountInGBP: Decimal {
        let total = splitAmountInGBP + splitRemainderAmountInGBP + commissionAmount
        var roundedTotal = Decimal()
        var totalCopy = total
        NSDecimalRound(&roundedTotal, &totalCopy, 2, .plain)
        return roundedTotal
    }
    
    func convertToPaymentCurrency(amount: Decimal) -> Decimal {
        // Safety fallback
        guard exchangeRate != 0 else { return amount }

        // No conversion if transaction currency matches payment method
        if currency == account.currency { return amount }

        return amount / exchangeRate
    }
}

// MARK: --- Extensions to return amounts as Strings for easier incorporation into Views and Reports
extension Transaction {
    
    
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
    func totalAmountDualCurrencyAsString( withSymbol: ShowCurrencySymbolsEnum = .always ) -> String {
        // NOTE: Here we are correctly mixin txAmount and totalAmount as we want to display the original transaction amount in say Yen and also the GBP amount posted on statements.
        var s1 = txAmountAsString(withSymbol: withSymbol)
        // There should be no commission in this case so it is safe to retrun txAmountAsString
        if currency == .GBP { return s1 }
        if withSymbol == .never { s1 = "" }
        if s1 != "" { s1 += "\n" }
        // Now we convert the totalAmount for display as stated earlier.
        let s2 = AmountFormatter.anyAmountAsString( amount: totalAmountInGBP, currency: .GBP, withSymbol: withSymbol )
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
        for account: ReconcilableAccounts,
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
            
            transaction.accountCD = account.rawValue
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
            NSPredicate(format: "accountCD == %d", temp.account.rawValue),
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

// MARK: --- Counter Trainsaction PairID Management
extension Transaction {
    /// Returns the single other transaction that shares the same `pairID` in the given context.
    /// - If `pairID` is nil, returns nil.
    /// - If zero or more than one other transaction exists, returns nil.
    /// - Does not create, delete, or mutate any objects.
    func counterTransaction(in context: NSManagedObjectContext) -> Transaction? {
        guard let pid = self.pairID else { return nil }

        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        // Find transactions with same pairID but exclude self
        request.predicate = NSPredicate(format: "pairID == %@ AND SELF != %@", pid as CVarArg, self)
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            return results.count == 1 ? results.first : nil
        } catch {
            // Do not mutate anything; surface the error for diagnostics
            print("counterTransaction fetch error: \(error)")
            return nil
        }
    }

    /// Assigns a pairID when creating a counterpart, enforcing the invariant that no more than two transactions share a pairID.
    /// - Parameters:
    ///   - other: the counterpart transaction to pair with (if nil, no action is taken)
    ///   - context: the managed object context to use for fetches and validation
    /// - Throws: `PairingError` when invariant violations would occur, or any fetch error encountered
    func assignPairIDforCounterpart(
        with other: Transaction?,
        in context: NSManagedObjectContext
    ) {
        guard let other = other else { return }
        
        
        let selfPID = self.pairID
        let otherPID = other.pairID
        
        // Case: both nil -> generate new UUID and assign to both
        if selfPID == nil && otherPID == nil {
            let pairID = UUID()
            self.pairID = pairID
            other.pairID = pairID
            return
        }
        
        // Case: exactly one non-nil -> copy the existing PID to the other transaction
        if let candidate = selfPID ?? otherPID {
            // Count existing transactions that already use this candidate
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.predicate = NSPredicate(format: "pairID == %@", candidate as CVarArg)
            
            do {
                let existing = try context.fetch(request)
                
                // Determine how many additional assignments would be needed (0,1,2)
                var additions = 0
                if selfPID != candidate { additions += 1 }
                if otherPID != candidate { additions += 1 }
                
                let resultantCount = existing.count + additions
                if resultantCount > 2 {
                    print( "Assigning pairID \(candidate.uuidString) would exceed the maximum of 2 transactions per pair")
                    return
                }
                
                // Assign missing pairID(s)
                if selfPID == nil {
                    self.pairID = candidate
                }
                if otherPID == nil {
                    other.pairID = candidate
                }
            } catch {
                print("assignPairID fetch error: \(error)")
            }
            return
        }
        
        // Case: both non-nil
        if let s = selfPID, let o = otherPID {
            if s == o {
                // already same pairID - nothing to do
                return
            } else {
                print("Conflicting pairID values: \(s.uuidString) vs \(o.uuidString)")
            }
        }
    }
    
}

extension Transaction {
    /// Returns true if pairID is nil or exactly two transactions share the pairID.
    /// On error, prints the error and returns false.
    func isPairValid(in context: NSManagedObjectContext) -> Bool {
        guard let pid = self.pairID else { return true }
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "pairID == %@", pid as CVarArg)
        do {
            let results = try context.fetch(request)
            return results.count == 2
        } catch {
            print("pair validation error: \(error)")
            return false
        }
    }
}
