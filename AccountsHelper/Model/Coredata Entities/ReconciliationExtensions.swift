//
//  ReconciliationExtensions.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 25/09/2025.
//

import Foundation
import CoreData

// MARK: --- CentsConvertible
extension Reconciliation: CentsConvertible {}

// MARK: --- INITIALISATION
extension Reconciliation {
    
    func resetPayPalCategoriesToUnknownX() {
        return 
        
        let context = self.managedObjectContext!
            context.performAndWait {
                let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
                
                // Filter for Bank of Scotland only (adjust this predicate if needed)
                request.predicate = NSPredicate(format: "paymentMethodCD == %d", PaymentMethod.BofSCA.rawValue)
                
                do {
                    let transactions = try context.fetch(request)
                    var changed = false
                    
                    for tx in transactions {
                        guard let payee = tx.payee, !payee.isEmpty else { continue }
                        
                        let trimmed = payee.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.uppercased().hasPrefix("PAYPAL") {
                            if tx.category != .unknown {
                                tx.category = .unknown
                                changed = true
                            }
                        }
                    }
                    
                    if changed {
                        try context.save()
                    }
                } catch {
                    NSLog("Failed to reset PayPal categories: \(error)")
                }
            }
        
    }


    // MARK: --- ConvenienceInit
    convenience init(
        context: NSManagedObjectContext,
        year: Int32,
        month: Int32,
        paymentMethod: PaymentMethod,
        statementDate: Date,
        endingBalance: Decimal,
        currency: Currency
    ) {
        self.init(context: context)
        self.periodYear = year
        self.periodMonth = month
        self.paymentMethodCD = paymentMethod.rawValue
        self.statementDate = statementDate
        self.endingBalanceCD = decimalToCents(endingBalance)
        self.currencyCD = currency.rawValue
        self.periodKey = Self.makePeriodKey(year: year, month: month, paymentMethod: paymentMethod)
    }
}

// MARK: --- COMPUTED PROPERTIES
extension Reconciliation {
    
    // MARK: --- AccountingPeriod
    var accountingPeriod: AccountingPeriod {
        AccountingPeriod(year: Int(periodYear), month: Int(periodMonth))
    }
    
    // MARK: --- Currency
    var currency: Currency {
        get { Currency(rawValue: currencyCD) ?? .unknown }
        set {
            switch paymentMethod {
            case .AMEX, .VISA, .BofSPV:
                currencyCD = Currency.GBP.rawValue
            default:
                currencyCD = newValue.rawValue
            }
        }
    }
    
    // MARK: --- TransactionsArray
    var transactionsArray: [Transaction] {
        (transactions as? Set<Transaction>)?
            .sorted(by: { $0.transactionDate ?? Date.distantPast < $1.transactionDate ?? Date.distantPast })
        ?? []
    }
    
    
    // MARK: --- IsClosed
    var isClosed: Bool { closed }
    
    // MARK: --- IsAnOpeningBalance
    var isAnOpeningBalance: Bool {
        guard let date = statementDate else { return false }
        let calendar = Calendar(identifier: .gregorian)
        let sentinel = calendar.date(from: DateComponents(year: 1, month: 1, day: 2))!
        return date < sentinel
    }
    
    // MARK: --- PaymentMethod
    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodCD) ?? .unknown }
        set { paymentMethodCD = newValue.rawValue }
    }
    
    // MARK: --- OpeningBalance
    var openingBalance: Decimal {
        previousEndingBalance
    }
    
    // MARK: --- EndingBalance
    var endingBalance: Decimal {
        get { Decimal(endingBalanceCD) / 100 }
        set { endingBalanceCD = decimalToCents(newValue) }
    }
    
    // MARK: --- PreviousEndingBalance
    var previousEndingBalance: Decimal {
        if let context = self.managedObjectContext,
           let previous = try? Reconciliation.fetchPrevious(for: self.paymentMethod, before: self.statementDate ?? Date.distantPast, context: context) {
            return previous.endingBalance
        }
        return 0
    }
    
    // MARK: --- previousStatementDate
    func previousStatementDate() -> Date? {
        if let context = self.managedObjectContext,
           let previous = try? Reconciliation.fetchPrevious(for: self.paymentMethod, before: self.statementDate ?? Date.distantPast, context: context) {
            return previous.statementDate
        }
        return Date.distantPast
    }
    
    // MARK: --- ReconciliationGap
    func reconciliationGap() -> Decimal {
        
        if isAnOpeningBalance { return 0 }
        
        let gap = previousEndingBalance - sumInNativeCurrency( /*mode: .checked*/ ) - endingBalance
        
//        if gap > 0.00 || gap < 0.00 { return 0 }
        let tolerance: Decimal = 0.01
        if gap.magnitude <= tolerance {
            return 0
        }
        return gap
    }
    
    // MARK: --- NetTransactionsInGBP
    var netTransactionsInGBP: Decimal {
        let txs = transactionsArray
        let sum = txs.reduce(Decimal(0)) { $0 + $1.totalAmountInGBP }
        return -sum
    }
//    var netTransactionsInGBP: Decimal {
//        guard let context = self.managedObjectContext else { return 0 }
//        let sum =  (try? fetchCandidateTransactions( ).reduce(Decimal(0)) { $0 + $1.totalAmountInGBP }) ?? 0
//        // Negate the total as we are storing a +ve number for money going out ie a Debit
//        // If we do not negate it the arithmatic does not work.
//        return -sum
//    }
    
    // MARK: --- NetTransactions
//    var netTransactions: Decimal {
//        guard let context = self.managedObjectContext else { return 0 }
//        let sum = (try? fetchCandidateTransactions(in: context).reduce(Decimal(0)) { $0 + $1.txAmount }) ?? 0
//        // Negate the total as we are storing a +ve number for money going out ie a Debit
//        // If we do not negate it the arithmatic does not work.
//        return -sum
//    }

    // MARK: --- TransactionEndDate
    var transactionEndDate: Date { self.statementDate ?? Date.distantPast }

    // MARK: --- TransactionStartDate
    var transactionStartDate: Date {
        guard let currentStatement = self.statementDate else { return Date.distantPast }
        if let context = self.managedObjectContext,
           let previous = try? Reconciliation.fetchPrevious(for: self.paymentMethod, before: currentStatement, context: context) {
            return Calendar.current.date(byAdding: .day, value: 1, to: previous.statementDate!)!
        }
        return currentStatement
    }
}

// MARK: --- String Formatters
extension Reconciliation {
    
    // MARK: --- EndingBalanceAsString
    func endingBalanceAsString() -> String {
        return AmountFormatter.anyAmountAsString(amount: endingBalance, currency: currency)
    }
    
    // MARK: --- PreviousEndingBalanceAsString
    func previousEndingBalanceAsString() -> String {
        return AmountFormatter.anyAmountAsString(amount: previousEndingBalance, currency: currency)
    }
    
    // MARK: --- OpeningBalanceAsString
    func openingBalanceAsString() -> String {
        return AmountFormatter.anyAmountAsString(amount: openingBalance, currency: currency)
    }
    
    // MARK: --- OpeningBalanceAsString
    func reconciliationGapAsString() -> String {
        return AmountFormatter.anyAmountAsString(amount: reconciliationGap(), currency: currency)
    }
    
    // MARK: --- SumInNativeCurrencyAsString
    func sumInNativeCurrencyAsString(withSymbol: ShowCurrencySymbolsEnum = .always) -> String {
        AmountFormatter.anyAmountAsString(amount: sumInNativeCurrency( /*mode: .all*/ ), currency: currency, withSymbol: withSymbol)
    }
    
    // MARK: --- SumCheckedInNativeCurrencyAsString
    func sumCheckedInNativeCurrencyAsString(withSymbol: ShowCurrencySymbolsEnum = .always) -> String {
        AmountFormatter.anyAmountAsString(amount: sumInNativeCurrency( /*mode: .checked*/ ), currency: currency, withSymbol: withSymbol)
    }
    
    // MARK: --- SumCheckedPositiveAmountsInNativeCurrencyAsString
    func sumCheckedPositiveAmountsInNativeCurrencyAsString(withSymbol: ShowCurrencySymbolsEnum = .always) -> String {
        AmountFormatter.anyAmountAsString(amount: sumPositiveAmountsInNativeCurrency( /*mode: .checked*/ ), currency: currency, withSymbol: withSymbol)
    }
    
    // MARK: --- SumCheckedNegativeAmountsInNativeCurrencyAsString
    func sumCheckedNegativeAmountsInNativeCurrencyAsString(withSymbol: ShowCurrencySymbolsEnum = .always) -> String {
        AmountFormatter.anyAmountAsString(amount: sumNegativeAmountsInNativeCurrency( /*mode: .checked*/ ), currency: currency, withSymbol: withSymbol)
    }
    
    
}
    
// MARK: --- RECONCILIATION
extension Reconciliation {

    // MARK: --- CanReOpenAccountingPeriod
    func canReopenAccountingPeriod( ) -> Bool {
        guard let context = self.managedObjectContext,
              let statementDate = self.statementDate else { return false }

        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(
            format: "paymentMethodCD == %d AND statementDate > %@ AND closed == YES",
            self.paymentMethod.rawValue,
            statementDate as NSDate
        )
        request.fetchLimit = 1

        do {
            let laterClosed = try context.fetch(request)
            return laterClosed.isEmpty
        } catch {
            print("Failed to check later closed reconciliations: \(error)")
            return false
        }
    }

    // MARK: --- CanClose
    func canClose( ) -> Bool {
//            guard let context = self.managedObjectContext else { return false }
        return reconciliationGap( ) == 0
            && isValid( )
            && isPreviousClosed( )
    }

    // MARK: --- CanDelete
    func canDelete( ) -> Bool {
        guard /*let context = self.managedObjectContext,*/
              !closed else { return false }
        
        if previousEndingBalance == 0 && hasLaterReconciliation( ) {
            return false
        }
        return true
    }

    // MARK: --- Close
    func close( ) throws {
        guard let context = self.managedObjectContext else { return }
        closed = true
        for tx in transactionsArray { tx.closed = closed }
        try context.save()
    }

    // MARK: --- KEEP AS WE REALLY SHOULD BE USING THIS I THINK BUT IN THE VIEW WE ARE MAKING OUR OWN
    // MARK: --- FetchCandidateTransactions
    // This fetch returns the superset of transactions in the period/payment method,
    // used to offer candidate transactions for adding/removing from this reconciliation.
    func fetchCandidateTransactions_NOT_USED( ) throws -> [Transaction] {
        guard let context = self.managedObjectContext else { return [] }
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = self.transactionsPredicate_NOT_USED()
        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: true)]
        return try context.fetch(request)
//        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
//        let start = self.transactionStartDate as NSDate
//        let end = self.transactionEndDate as NSDate
//        request.predicate = NSPredicate(
//            format: "paymentMethodCD == %d AND transactionDate >= %@ AND transactionDate <= %@",
//            self.paymentMethod.rawValue,
//            start,
//            end
//        )
//        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: true)]
//        return try context.fetch(request)
    }

    // MARK: --- HasLaterReconciliation
    func hasLaterReconciliation( ) -> Bool {
        guard let context = self.managedObjectContext,
              let statementDate = self.statementDate else { return false }
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(
            format: "paymentMethodCD == %d AND statementDate > %@",
            self.paymentMethod.rawValue,
            statementDate as NSDate
        )
        request.fetchLimit = 1
        do {
            let later = try context.fetch(request)
            return !later.isEmpty
        } catch {
            print("Failed to check later reconciliations: \(error)")
            return false
        }
    }

    // MARK: --- IsBalanced
    func isBalanced( ) -> Bool { reconciliationGap() == 0 }

    // MARK: --- IsPreviousClosed
    func isPreviousClosed( ) -> Bool {
        guard let context = self.managedObjectContext,
              let previous = try? Reconciliation.fetchPrevious(for: self.paymentMethod, before: self.statementDate ?? Date.distantPast, context: context) else {
            return true
        }
        return previous.closed
    }

    // MARK: --- IsValid
    func isValid( ) -> Bool {
//        do {
//            let txs = try fetchCandidateTransactions(in: context)
            return transactionsArray.allSatisfy { $0.isValid() }
//        } catch {
//            print("Failed to fetch transactions: \(error)")
//            return false
//        }
    }
    

    // MARK: --- KEEP AS WE REALLY SHOULD BE USING THIS I THINK BUT IN THE VIEW WE ARE MAKING OUR OWN
    // MARK: --- TransactionsPredicate
    func transactionsPredicate_NOT_USED( ) -> NSPredicate {
        var predicates: [NSPredicate] = []
        
        if isClosed {
            // Closed: all transactions for the periodKey
            predicates.append(NSPredicate(format: "periodKey == %@", periodKey ?? ""))
        } else {
            // Open: transactions within reconciliation date range ±14 days
            if let start = previousStatementDate(), let end = statementDate {
                let adjustedStart = Calendar.current.date(byAdding: .day, value: -14, to: start)! as NSDate
                let adjustedEnd   = Calendar.current.date(byAdding: .day, value: 14, to: end)! as NSDate
                predicates.append(NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", adjustedStart, adjustedEnd))
            }
            // Exclude transactions that are already closed (assigned to another reconciliation)
            predicates.append(NSPredicate(format: "closed == NO"))
        }
        
        // Always filter by payment method
        predicates.append(NSPredicate(format: "paymentMethodCD == %@", NSNumber(value: paymentMethod.rawValue)))
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

//    func transactionsPredicate() -> NSPredicate {
//        var predicates: [NSPredicate] = []
//        
//        // --- Date range filter
//        if let start = previousStatementDate(), let end = statementDate {
//            predicates.append(NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start as NSDate, end as NSDate))
//        }
//        
//        // --- Payment method filter
//            predicates.append(NSPredicate(format: "paymentMethodCD == %@", NSNumber(value: paymentMethod.rawValue)))
//        
//        guard !predicates.isEmpty else { return NSPredicate(value: true) } // matches all if nothing to filter
//        
//        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
//    }
    


    // MARK: --- Reopen
    func reopen( ) throws {
        
//        resetPayPalCategoriesToUnknown()
        
        guard let context = self.managedObjectContext else {
            print("No managed object context found!")
            return
        }

        print("Transactions in context:")
        for tx in transactionsArray {
            print("Transaction \(tx.objectID): closed = \(tx.closed)")
        }
        
        for tx in transactionsArray { tx.closed = false }
        closed = false
        try context.save()
    }

    // MARK: --- TransactionsTotalInGBP
//    func transactionsTotalInGBP(in context: NSManagedObjectContext) throws -> Decimal {
//        let txs = try fetchCandidateTransactions(in: context)
//        return txs.reduce(Decimal(0)) { $0 + $1.totalAmountInGBP }
//    }
    
    // MARK: --- SumInNativeCurrency
//    var sumInNativeCurrency: Decimal {
//        guard let context = managedObjectContext else { return 0 }
//        
//        do {
//            let txs = try fetchCandidateTransactions(in: context)
//            
//            let total: Decimal
//            switch currency {
//            case .GBP:
//                // Sum all transactions in GBP
//                total = txs.reduce(Decimal(0)) { $0 + $1.txAmountInGBP }
//            default:
//                // Sum all transactions in their native currency
//                total = txs.reduce(Decimal(0)) { $0 + $1.txAmount }
//            }
//            
//            // Apply existing convention: positive = money going out / debit
//            return total
//        } catch {
//            print("Failed to fetch transactions for sumInNativeCurrency: \(error)")
//            return 0
//        }
//    }
    

    // MARK: --- SumInNativeCurrency
    func sumInNativeCurrency( ) -> Decimal {
        // Sum all postings, already converted to the reconciliation currency
        return transactionsArray.postings.reduce(0) { sum, posting in
            sum + posting.amount
        }
    }

    // MARK: --- SumPositiveAmountsInNativeCurrency
    func sumPositiveAmountsInNativeCurrency() -> Decimal {
        return transactionsArray.postings
            .reduce(0) { sum, posting in
                if posting.amount > 0 {
                    return sum + posting.amount
                } else {
                    return sum
                }
            }
    }

    // MARK: --- Sum Negative Amounts In Native Currency
    func sumNegativeAmountsInNativeCurrency() -> Decimal {
        return transactionsArray.postings
            .reduce(0) { sum, posting in
                if posting.amount < 0 {
                    return sum + posting.amount
                } else {
                    return sum
                }
            }
    }


    // MARK: --- CreateNew
    @discardableResult
    static func createNew(
        paymentMethod: PaymentMethod,
        period: AccountingPeriod,
        statementDate: Date,
        endingBalance: Decimal,
        in context: NSManagedObjectContext
    ) throws -> Reconciliation {
        _ = try ensureBaseline(for: paymentMethod, in: context)
        if let existing = try fetchOne(for: period, paymentMethod: paymentMethod, context: context) {
            return existing
        }
        let rec = Reconciliation(
            context: context,
            year: Int32(period.year),
            month: Int32(period.month),
            paymentMethod: paymentMethod,
            statementDate: statementDate,
            endingBalance: endingBalance,
            currency: paymentMethod.currency
        )
        try context.save()
        return rec
    }

    // MARK: --- EnsureBaseline
    static func ensureBaseline(for paymentMethod: PaymentMethod, in context: NSManagedObjectContext) throws -> Reconciliation {
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(format: "paymentMethodCD == %d", paymentMethod.rawValue)
        request.fetchLimit = 1
        if let existing = try context.fetch(request).first {
            return existing
        }
        let baselineDate = Date.distantPast
        let year = Int32(Calendar.current.component(.year, from: baselineDate))
        let month = Int32(Calendar.current.component(.month, from: baselineDate))
        let baseline = Reconciliation(
            context: context,
            year: year,
            month: month,
            paymentMethod: paymentMethod,
            statementDate: baselineDate,
            endingBalance: 0,
            currency: paymentMethod.currency
        )
        try context.save()
        return baseline
    }

    // MARK: --- FetchPrevious
    static func fetchPrevious(
        for paymentMethod: PaymentMethod,
        before date: Date,
        context: NSManagedObjectContext
    ) throws -> Reconciliation? {
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(
            format: "paymentMethodCD == %d AND statementDate < %@",
            paymentMethod.rawValue,
            date as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "statementDate", ascending: false)]
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // MARK: --- MakePeriodKey
    static func makePeriodKey(year: Int32, month: Int32, paymentMethod: PaymentMethod) -> String {
        "\(year)-\(String(format: "%02d", month))-\(paymentMethod.code)"
    }
}

// MARK: --- FETCH HELPERS
extension Reconciliation {

    static func fetch(
        for period: AccountingPeriod,
        context: NSManagedObjectContext
    ) throws -> [Reconciliation] {
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(
            format: "periodYear == %d AND periodMonth == %d",
            period.year, period.month
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "paymentMethodCD", ascending: true),
            NSSortDescriptor(key: "statementDate", ascending: true)
        ]
        return try context.fetch(request)
    }

    static func fetch(
        for period: AccountingPeriod,
        paymentMethod: PaymentMethod,
        context: NSManagedObjectContext
    ) throws -> [Reconciliation] {
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(
            format: "periodYear == %d AND periodMonth == %d AND paymentMethodCD == %d",
            period.year, period.month, paymentMethod.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(key: "statementDate", ascending: true)]
        return try context.fetch(request)
    }

    static func fetchOne(
        for period: AccountingPeriod,
        paymentMethod: PaymentMethod,
        context: NSManagedObjectContext
    ) throws -> Reconciliation? {
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(
            format: "periodYear == %d AND periodMonth == %d AND paymentMethodCD == %d",
            period.year, period.month, paymentMethod.rawValue
        )
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
