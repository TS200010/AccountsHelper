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

    // MARK: - Computed Properties for CD fields
    var method: PaymentMethod {
        PaymentMethod(rawValue: paymentMethodCD) ?? .unknown
    }

    var currency: Currency {
        get { Currency(rawValue: currencyCD) ?? .unknown }
        set { currencyCD = newValue.rawValue }
    }

    var endingBalance: Decimal {
        get { Decimal(endingBalanceCD) / 100 }
        set { endingBalanceCD = decimalToCents(newValue) }
    }

    var accountingPeriod: AccountingPeriod {
        AccountingPeriod(year: Int(periodYear), month: Int(periodMonth))
    }


    // MARK: - Fetch Helpers

    /// Fetch all reconciliations for a given period and payment method
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

    /// Fetch all reconciliations for a given period (all payment methods)
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

    /// Fetch a single reconciliation for a period + method
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
