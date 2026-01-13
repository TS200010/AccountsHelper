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
        return Date.distantFuture
    }
    
    // MARK: --- ReconciliationGap
    func reconciliationGap() -> Decimal {

        if isAnOpeningBalance { return 0 }
        
        let gap = previousEndingBalance - sumInNativeCurrency( /*mode: .checked*/ ) - endingBalance
        
        return gap
    }
    
    // MARK: --- NetTransactionsInGBP
    var netTransactionsInGBP: Decimal {
        guard let context = self.managedObjectContext else { return 0 }
        let sum =  (try? fetchCandidateTransactions(in: context).reduce(Decimal(0)) { $0 + $1.totalAmountInGBP }) ?? 0
        // Negate the total as we are storing a +ve number for money going out ie a Debit
        // If we do not negate it the arithmatic does not work.
        return -sum
    }
    
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
    
}
    
// MARK: --- RECONCILIATION
extension Reconciliation {

    // MARK: --- CanReOpenAccountingPeriod
    func canReopenAccountingPeriod(in context: NSManagedObjectContext) -> Bool {
        guard let statementDate = self.statementDate else { return false }

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

    // MARK: --- CanCloseAccountingPeriod
    func canCloseAccountingPeriod(in context: NSManagedObjectContext) -> Bool {
        reconciliationGap( ) == 0
            && isValid(in: context)
            && isPreviousClosed(in: context)
    }

    // MARK: --- CanDelete
    func canDelete(in context: NSManagedObjectContext) -> Bool {
        guard !closed else { return false }
        if previousEndingBalance == 0 && hasLaterReconciliation(in: context) {
            return false
        }
        return true
    }

    // MARK: --- Close
    func close(in context: NSManagedObjectContext) throws {
        closed = true
        let txs = try fetchCandidateTransactions(in: context)
        for tx in txs { tx.closed = true }
        try context.save()
    }

    // MARK: --- FetchCandidateTransactions
    // This fetch returns the superset of transactions in the period/payment method,
    // used to offer candidate transactions for adding/removing from this reconciliation.
    func fetchCandidateTransactions(in context: NSManagedObjectContext) throws -> [Transaction] {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        let start = self.transactionStartDate as NSDate
        let end = self.transactionEndDate as NSDate
        request.predicate = NSPredicate(
            format: "paymentMethodCD == %d AND transactionDate >= %@ AND transactionDate <= %@",
            self.paymentMethod.rawValue,
            start,
            end
        )
        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: true)]
        return try context.fetch(request)
    }

    // MARK: --- HasLaterReconciliation
    func hasLaterReconciliation(in context: NSManagedObjectContext) -> Bool {
        guard let statementDate = self.statementDate else { return false }
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
    func isBalanced(in context: NSManagedObjectContext) -> Bool { reconciliationGap() == 0 }

    // MARK: --- IsPreviousClosed
    func isPreviousClosed(in context: NSManagedObjectContext) -> Bool {
        guard let previous = try? Reconciliation.fetchPrevious(for: self.paymentMethod, before: self.statementDate ?? Date.distantPast, context: context) else {
            return true
        }
        return previous.closed
    }

    // MARK: --- IsValid
    func isValid(in context: NSManagedObjectContext) -> Bool {
        do {
            let txs = try fetchCandidateTransactions(in: context)
            return txs.allSatisfy { $0.isValid() }
        } catch {
            print("Failed to fetch transactions: \(error)")
            return false
        }
    }
    

    // MARK: --- TransactionsPredicate
    func transactionsPredicate() -> NSPredicate {
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
    func reopen(in context: NSManagedObjectContext) throws {
        closed = false
        let txs = try fetchCandidateTransactions(in: context)
        for tx in txs { tx.closed = false }
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
    
    // MARK: --- TransactionSumMode
//    enum TransactionSumMode {
//        case all
//        case checked
//    }

    // MARK: --- SumInNativeCurrency
    func sumInNativeCurrency(/*mode: TransactionSumMode*/) -> Decimal {
        //        guard let context = managedObjectContext else { return 0 }
        
        do {
            // Fetch using the reconciliation’s predicate
            //            let txs = try fetchCandidateTransactions(in: context)
            let txs = self.transactionsArray
            
            // Optional filter
            //            let filtered: [Transaction]
            //            switch mode {
            //            case .all:
            //                filtered = txs
            //            case .checked:
            //                filtered = txs.filter { $0.reconciliation != nil }
            //            }
            
            // Currency-sensitive summing
            let total: Decimal
            switch currency {
            case .GBP:
                total = txs.reduce(0) { $0 + $1.txAmountInGBP }
            default:
                total = txs.reduce(0) { $0 + $1.txAmount }
            }
            
            //            print(total)
            return total
            
            //        } catch {
            //            print("Failed to fetch transactions for sumInNativeCurrency: \(error)")
            //            return 0
            //        }
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
