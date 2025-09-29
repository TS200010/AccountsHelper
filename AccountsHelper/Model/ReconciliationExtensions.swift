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

extension Reconciliation: CentsConvertible {}

extension Reconciliation {
    
    // MARK: - Composite Key
    static func makePeriodKey(year: Int32, month: Int32, paymentMethod: PaymentMethod) -> String {
        "\(year)-\(String(format: "%02d", month))-\(paymentMethod.code)"
    }
    
    // MARK: - Convenience Initializer
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
    
    // MARK: - Computed Properties
    
    var paymentMethod: PaymentMethod {
        PaymentMethod(rawValue: paymentMethodCD) ?? .unknown
    }
    
    var currency: Currency {
        get { Currency(rawValue: currencyCD) ?? .unknown }
        set {
            switch paymentMethod {
            case .AMEX, .VISA, .bankOfScotland:
                currencyCD = Currency.GBP.rawValue
            default:
                currencyCD = newValue.rawValue
            }
        }
    }
    
    var endingBalance: Decimal {
        get { Decimal(endingBalanceCD) / 100 }
        set { endingBalanceCD = decimalToCents(newValue) }
    }
    
    var accountingPeriod: AccountingPeriod {
        AccountingPeriod(year: Int(periodYear), month: Int(periodMonth))
    }
    
    // MARK: - Start or Fetch Reconciliation
    
    /// Returns a baseline reconciliation for a payment method if none exist
    static func ensureBaseline(for paymentMethod: PaymentMethod, in context: NSManagedObjectContext) throws -> Reconciliation {

        // Check if *any* reconciliation exists for this method
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(format: "paymentMethodCD == %d", paymentMethod.rawValue)
        request.fetchLimit = 1
        
        if let existing = try context.fetch(request).first {
            return existing // Already exists
        }
        
        // Create baseline with Jan 1, 0001
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
    
    
    @discardableResult
    static func createNew(
        paymentMethod: PaymentMethod,
        period: AccountingPeriod,
        statementDate: Date,
        endingBalance: Decimal,
        in context: NSManagedObjectContext
    ) throws -> Reconciliation {

        // Ensure baseline exists
        _ = try ensureBaseline(for: paymentMethod, in: context)
        
        // Check if reconciliation already exists
        if let existing = try fetchOne(for: period, paymentMethod: paymentMethod, context: context) {
            return existing
        }
        
        // Create new reconciliation with user-entered date
        let rec = Reconciliation(
            context: context,
            year: Int32(period.year),
            month: Int32(period.month),
            paymentMethod: paymentMethod,
            statementDate: statementDate, // ✅ user-entered
            endingBalance: endingBalance,
            currency: paymentMethod.currency
        )
        
        try context.save()
        return rec
    }
    
    
//    static func ensureStartingReconciliation(
//        for paymentMethod: PaymentMethod,
//        in context: NSManagedObjectContext,
//        startDate: Date = Date.distantPast
//    ) throws -> Reconciliation {
//        
//        // Check if *any* reconciliation exists for this method
//        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
//        request.predicate = NSPredicate(format: "paymentMethodCD == %d", paymentMethod.rawValue)
//        request.fetchLimit = 1
//        
//        if let existing = try context.fetch(request).first {
//            return existing // Already initialized
//        }
//        
//        // Derive period from start date
//        let year = Int32(Calendar.current.component(.year, from: startDate))
//        let month = Int32(Calendar.current.component(.month, from: startDate))
//        
//        let dummy = Reconciliation(
//            context: context,
//            year: year,
//            month: month,
//            paymentMethod: paymentMethod,
//            statementDate: startDate,
//            endingBalance: 0,
//            currency: paymentMethod.currency
//        )
//        
//        try context.save()
//        return dummy
//    }
    
    // Fetch the latest reconciliation before a given date for a payment method
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
    
    // Compute the start date for transactions (day after previous reconciliation)
    var transactionStartDate: Date {
        
        guard let currentStatement = self.statementDate else {
            return Date.distantPast
        }
        
        if let context = self.managedObjectContext,
           let previous = try? Reconciliation.fetchPrevious(for: self.paymentMethod, before: self.statementDate!, context: context) {
            return Calendar.current.date(byAdding: .day, value: 1, to: previous.statementDate!)!
        }
        return currentStatement // fallback
    }
    
    var transactionEndDate: Date {
        return self.statementDate ?? Date.distantPast
    }
    
//    func fetchTransactions(in context: NSManagedObjectContext) throws -> [Transaction] {
//        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
//        request.predicate = NSPredicate(
//            format: "paymentMethodCD == %d AND transactionDate >= %@ AND transactionDate <= %@",
//            self.paymentMethod.rawValue,
//            self.transactionStartDate as NSDate,
//            self.transactionEndDate as NSDate
//        )
//        request.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: true)]
//        return try context.fetch(request)
//    }
    
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
    
    
    /// Returns the difference between the expected ending balance
    /// (previous reconciliation balance + sum of transactions)
    /// and the actual reconciliation ending balance.
//    func reconciliationGap(in context: NSManagedObjectContext) throws -> Decimal {
//        let txs = try fetchTransactions(in: context)
//        let sum = txs.reduce(Decimal(0)) { total, tx in
//            total + tx.txAmount
//        }
//        
//        let previousBalance: Decimal
//        if let previous = try Reconciliation.fetchPrevious(
//            for: self.paymentMethod,
//            before: self.statementDate!,
//            context: context
//        ) {
//            previousBalance = previous.endingBalance
//        } else {
//            previousBalance = 0
//        }
//        
//        let expectedBalance = previousBalance + sum
//        return expectedBalance - self.endingBalance
//    }
    
    func reconciliationGap(in context: NSManagedObjectContext) throws -> Decimal {
        let txs = try fetchTransactions(in: context)
        let sum = txs.reduce(Decimal(0)) { total, tx in
            total + tx.txAmount
        }

        let previousBalance: Decimal
        if let prev = try Reconciliation.fetchPrevious(for: self.paymentMethod, before: self.transactionEndDate, context: context) {
            previousBalance = prev.endingBalance
        } else {
            previousBalance = 0
        }

        let expectedBalance = previousBalance + sum
        return expectedBalance - (self.endingBalance)
    }
    
    /// Convenience: check if out of balance is exactly zero
    func isBalanced(in context: NSManagedObjectContext) throws -> Bool {
        try reconciliationGap(in: context) == 0
    }
    
    
    
    // MARK: - Fetch Helpers
    
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
