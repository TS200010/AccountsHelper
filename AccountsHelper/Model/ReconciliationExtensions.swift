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
| ------------------ | ------------------ | -------------------------------------------------------- |
| Property / Method  | Type               | Description                                              |
| ------------------ | ------------------ | -------------------------------------------------------- |
| `endingBalanceCD`  | `Int32`            | Core Data storage for ending balance in cents            |
| `endingBalance`    | `Decimal`          | Computed ending balance (`endingBalanceCD / 100`)        |
| `paymentMethodCD`  | `Int32`            | Core Data storage for payment method enum raw value      |
| `method`           | `PaymentMethod`    | Computed property for type-safe access to payment method |
| `currencyCD`       | `Int32`            | Core Data storage for currency enum raw value            |
| `currency`         | `Currency`         | Computed property for type-safe access to currency       |
| `periodYear`       | `Int32`            | Accounting period year                                   |
| `periodMonth`      | `Int32`            | Accounting period month (1–12)                           |
| `periodKey`        | `String`           | Unique composite key `"year-month-method"`               |
| `statementDate`    | `Date`             | Actual statement date of the reconciliation              |
| `accountingPeriod` | `AccountingPeriod` | Computed struct for grouping/display of period           |
| ------------------ | ------------------ | -------------------------------------------------------- |
*/

/*
 |------------------------------|-----------------------|-----------------------------------------------------------------------|
 | Property / Method            | Type                  | Description                                                           |
 |------------------------------|-----------------------|-----------------------------------------------------------------------|
 | `method`                     | PaymentMethod         | Computed property to access the payment method enum                   |
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
    static func makePeriodKey(year: Int32, month: Int32, method: PaymentMethod) -> String {
        "\(year)-\(String(format: "%02d", month))-\(method.rawValue)"
    }

    // MARK: - Convenience Initializer
    convenience init(
        context: NSManagedObjectContext,
        year: Int32,
        month: Int32,
        method: PaymentMethod,
        statementDate: Date,
        endingBalance: Decimal,
        currency: Currency
    ) {
        self.init(context: context)
        self.periodYear = year
        self.periodMonth = month
        self.paymentMethodCD = method.rawValue
        self.statementDate = statementDate
        self.endingBalanceCD = decimalToCents(endingBalance)
        self.currencyCD = currency.rawValue
        self.periodKey = Self.makePeriodKey(year: year, month: month, method: method)
    }

    // MARK: - Computed Properties

    var method: PaymentMethod {
        PaymentMethod(rawValue: paymentMethodCD) ?? .unknown
    }

    var currency: Currency {
        get { Currency(rawValue: currencyCD) ?? .unknown }
        set {
            switch method {
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

    /// Returns an existing reconciliation for a period + method, or creates a new one
    @discardableResult
    static func startOrFetch(
        method: PaymentMethod,
        period: AccountingPeriod,
        endingBalance: Decimal = 0,
        currency: Currency? = nil, // optional, only used for Cash
        in context: NSManagedObjectContext
    ) throws -> Reconciliation {

        // Return existing if present
        if let existing = try fetchOne(for: period, method: method, context: context) {
            return existing
        }

        // Determine currency
        let finalCurrency: Currency
        switch method {
        case .AMEX, .VISA, .bankOfScotland:
            finalCurrency = .GBP
        case .CASH:
            finalCurrency = currency ?? .GBP
        default:
            finalCurrency = currency ?? .GBP
        }

        // Create new reconciliation
        let rec = Reconciliation(
            context: context,
            year: Int32(period.year),
            month: Int32(period.month),
            method: method,
            statementDate: Date(),
            endingBalance: endingBalance,
            currency: finalCurrency
        )

        try context.save()
        return rec
    }

    // MARK: - Fetch Helpers

    static func fetch(
        for period: AccountingPeriod,
        method: PaymentMethod,
        context: NSManagedObjectContext
    ) throws -> [Reconciliation] {
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(
            format: "periodYear == %d AND periodMonth == %d AND paymentMethodCD == %d",
            period.year, period.month, method.rawValue
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
        method: PaymentMethod,
        context: NSManagedObjectContext
    ) throws -> Reconciliation? {
        let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
        request.predicate = NSPredicate(
            format: "periodYear == %d AND periodMonth == %d AND paymentMethodCD == %d",
            period.year, period.month, method.rawValue
        )
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
