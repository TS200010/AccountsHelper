//
//  ReconciliationExtensions.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 25/09/2025.
//

import Foundation
import CoreData

/*
     @NSManaged public var statementDate: Date?
     @NSManaged public var paymentMethodCD: Int32
     @NSManaged public var periodYear: Int32
     @NSManaged public var periodMonth: Int32
     @NSManaged public var periodKey: String?
     @NSManaged public var endingBalanceCD: Int32
     @NSManaged public var currencyCD: Int32
 */

/*
| ------------------ | ------------------ | ---------------------------------------------------- |
| Property / Method  | Type               | Description                                          |
| ------------------ | ------------------ | ---------------------------------------------------- |
| `endingBalanceCD`  | `Int32`            | Core Data storage for ending balance in cents        |
| `endingBalance`    | `Decimal`          | Computed ending balance (`endingBalanceCD / 100`)    |
| `paymentMethodCD`  | `Int32`            | Core Data storage for payment method enum raw value  |
| `paymentMethod`    | `PaymentMethod`    | Computed property for type-safe access to pmt method |
| `currencyCD`       | `Int32`            | Core Data storage for currency enum raw value        |
| `currency`         | `Currency`         | Computed property for type-safe access to currency   |
| `periodYear`       | `Int32`            | Accounting period year                               |
| `periodMonth`      | `Int32`            | Accounting period month (1–12)                       |
| `periodKey`        | `String`           | Unique composite key `"year-month-method"`           |
| `statementDate`    | `Date`             | Actual statement date of the reconciliation          |
| `accountingPeriod` | `AccountingPeriod` | Computed struct for grouping/display of period       |
| ------------------ | ------------------ | ---------------------------------------------------- |
*/

/*
 |------------------------------|-----------------------|-----------------------------------------------------------------------|
 | Property / Method            | Type                  | Description                                                           |
 |------------------------------|-----------------------|-----------------------------------------------------------------------|
 | `paymentMethod`              | PaymentMethod         | Computed property to access the payment method enum                   |
 | `currency`                   | Currency              | Computed property for currency; enforced GBP for AMEX, VISA, BoS      |
 | `endingBalance`              | Decimal               | Computed balance in units (from endingBalanceCD in cents)             |
 | `accountingPeriod`           | AccountingPeriod      | Computed struct grouping periodYear and periodMonth                   |
 | `startOrFetch(method:period:endingBalance:currency:in:)`
 |                              | Reconciliation        | Returns existing or creates new reconciliation for period + method    |
 | `fetch(for:method:context:)` | [Reconciliation]      | Fetch all reconciliations for a specific period and payment method    |
 | `fetch(for:context:)`        | [Reconciliation]      | Fetch all reconciliations for a specific period (all payment methods) |
 | `fetchOne(for:method:context:)` | Reconciliation?    | Fetch a single reconciliation for a period + payment method           |
 |------------------------------|-----------------------|-----------------------------------------------------------------------|

 */

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
    
    // MARK: --- EndingBalance
    var endingBalance: Decimal {
        get { Decimal(endingBalanceCD) / 100 }
        set { endingBalanceCD = decimalToCents(newValue) }
    }
    
    // MARK: --- EndingBalanceInGBP
    var endingBalanceInGBP: Decimal {
        return endingBalance
    }
    
    // MARK: --- NewBalanceInGBP
    var newBalanceInGBP: Decimal {
        return endingBalance
    }
    
    // MARK: --- IsClosed
    var isClosed: Bool {
        closed
    }
    
    // MARK: --- PaymentMethod
    var paymentMethod: PaymentMethod {
        PaymentMethod(rawValue: paymentMethodCD) ?? .unknown
    }
    
    // MARK: --- PreviousBalanceInGBP
    var previousBalanceInGBP: Decimal {
        if let context = self.managedObjectContext,
           let previous = try? Reconciliation.fetchPrevious(for: self.paymentMethod, before: self.statementDate ?? Date.distantPast, context: context) {
            return previous.endingBalance
        }
        return 0
    }
    
    // MARK: --- TotalTransactionsInGBP
    var totalTransactionsInGBP: Decimal {
        guard let context = self.managedObjectContext else { return 0 }
        return (try? fetchTransactions(in: context).reduce(Decimal(0)) { $0 + $1.totalAmountInGBP }) ?? 0
    }
    
    // MARK: --- TransactionEndDate
    var transactionEndDate: Date {
        return self.statementDate ?? Date.distantPast
    }
    
    // MARK: --- TransactionStartDate
    var transactionStartDate: Date {
        guard let currentStatement = self.statementDate else {
            return Date.distantPast
        }
        if let context = self.managedObjectContext,
           let previous = try? Reconciliation.fetchPrevious(for: self.paymentMethod, before: self.statementDate!, context: context) {
            return Calendar.current.date(byAdding: .day, value: 1, to: previous.statementDate!)!
        }
        return currentStatement
    }
}

// MARK: --- RECONCILIATION
extension Reconciliation {
    
    // MARK: --- CanCloseAccountingPeriod
    func canCloseAccountingPeriod(in context: NSManagedObjectContext) -> Bool {
        return reconciliationGap(in: context) == 0 && isValid(in: context)
    }
    
    // MARK: --- CreditsTotalInGBP
//    func XcreditsTotalInGBP(in context: NSManagedObjectContext) throws -> Decimal {
//        let txs = try fetchTransactions(in: context).filter { $0.debitCredit == .CR }
//        return txs.reduce(Decimal(0)) { $0 + $1.totalAmountInGBP }
//    }
    
    // MARK: --- DebitsTotalInGBP
//    func XdebitsTotalInGBP(in context: NSManagedObjectContext) throws -> Decimal {
//        let txs = try fetchTransactions(in: context).filter { $0.debitCredit == .DR }
//        return txs.reduce(Decimal(0)) { $0 + $1.totalAmountInGBP }
//    }
    
    // MARK: --- Close
    func close(in context: NSManagedObjectContext) throws -> Void {
        
        closed = true
        let txs = try fetchTransactions(in: context)
        for tx in txs {
            tx.closed = true
        }
        try context.save()
    }
    
    
    // MARK: --- FetchTransactions
    func fetchTransactions(in context: NSManagedObjectContext) throws -> [Transaction] {
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
    
    // MARK: --- IsBalanced
    func isBalanced(in context: NSManagedObjectContext) -> Bool {
        reconciliationGap(in: context) == 0
    }
    
    // MARK: --- IsValid
    func isValid(in context: NSManagedObjectContext) -> Bool {
        do {
            let txs = try fetchTransactions(in: context)
            return txs.allSatisfy { $0.isValid() }
        } catch {
            print("Failed to fetch transactions: \(error)")
            return false
        }
    }
    
    // MARK: --- ReconciliationGap
    func reconciliationGap(in context: NSManagedObjectContext) -> Decimal {

        do {
            let txs = try fetchTransactions(in: context)
            let sumInGBP = txs.reduce(Decimal(0)) { $0 + $1.totalAmountInGBP }
            
            let previousBalance: Decimal
            if let prev = try? Reconciliation.fetchPrevious(for: self.paymentMethod, before: self.transactionEndDate, context: context) {
                previousBalance = prev.endingBalance
            } else {
                previousBalance = 0
            }
            
            let expectedBalance = previousBalance + sumInGBP
            let safePreviousBalance = previousBalance
            let safeSumInGBP = sumInGBP
            let expectedBalance2 = safePreviousBalance + safeSumInGBP
            let gap = expectedBalance - self.endingBalance
            
            return expectedBalance - self.endingBalance
        } catch {
            print("Failed to compute reconciliation gap: \(error)")
            return 0
        }
    }
    
    // MARK: --- TransactionsTotalInGBP
    func transactionsTotalInGBP(in context: NSManagedObjectContext) throws -> Decimal {
        let txs = try fetchTransactions(in: context)
        return txs.reduce(Decimal(0)) { $0 + $1.totalAmountInGBP }
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
