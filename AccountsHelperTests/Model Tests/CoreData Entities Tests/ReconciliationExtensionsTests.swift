//
//  ReconciliationExtensionsTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import CoreData
import Testing
@testable import AccountsHelper

@MainActor
struct ReconciliationExtensionsTests {

    // MARK: --- Environment / Context
    let context = CoreDataTestHelpers.makeInMemoryContext()

    // MARK: --- Helper Methods
    private func makeReconciliation(
        paymentMethod: ReconcilableAccounts = .VISA,
        year: Int32 = 2025,
        month: Int32 = 10,
        statementDate: Date = Date(),
        endingBalance: Decimal = 100,
        closed: Bool = false
    ) -> Reconciliation {
        let rec = Reconciliation(
            context: context,
            year: year,
            month: month,
            paymentMethod: paymentMethod,
            statementDate: statementDate,
            endingBalance: endingBalance,
            currency: paymentMethod.currency
        )
        rec.closed = closed
        try? context.save()
        return rec
    }

    private func makeTransaction(
        reconciliation: Reconciliation,
        amount: Decimal = 50,
        date: Date = Date(),
        closed: Bool = false
    ) -> Transaction {
        let tx = Transaction(context: context)
        tx.txAmount = amount
        tx.transactionDate = date
        tx.paymentMethodCD = reconciliation.paymentMethodCD
        tx.closed = closed
        try? context.save()
        return tx
    }

    // MARK: --- Initialization Tests
    @Test
    func testConvenienceInitSetsProperties() async throws {
        let date = Date()
        let rec = Reconciliation(
            context: context,
            year: 2025,
            month: 10,
            paymentMethod: .VISA,
            statementDate: date,
            endingBalance: 123.45,
            currency: .USD
        )
        #expect(rec.periodYear == 2025)
        #expect(rec.periodMonth == 10)
        #expect(rec.paymentMethodCD == ReconcilableAccounts.VISA.rawValue)
        #expect(rec.statementDate == date)
        #expect(rec.endingBalance == 123.45)
        #expect(rec.currency == .USD)
        #expect(rec.periodKey == Reconciliation.makePeriodKey(year: 2025, month: 10, paymentMethod: .VISA))
    }

    @Test
    func testCreateNewReturnsExistingIfPresent() async throws {
        let period = AccountingPeriod(year: 2025, month: 10)
        let rec1 = makeReconciliation(year: 2025, month: 10)
        let rec2 = try Reconciliation.createNew(
            paymentMethod: .VISA,
            period: period,
            statementDate: Date(),
            endingBalance: 50,
            in: context
        )
        #expect(rec1.objectID == rec2.objectID)
    }

    @Test
    func testEnsureBaselineCreatesIfNone() async throws {
        let baseline = try Reconciliation.ensureBaseline(for: .AMEX, in: context)
        #expect(baseline.periodYear > 0)
        #expect(baseline.periodMonth > 0)
        #expect(baseline.account == .AMEX)
        #expect(baseline.endingBalance == 0)
    }

    // MARK: --- Computed Property Tests
    @Test
    func testCurrencyOverrideForAMEXAndVISA() async throws {
        let rec = makeReconciliation(paymentMethod: .AMEX)
        rec.currency = .USD
        #expect(rec.currency == .GBP) // AMEX overrides to GBP
    }

    @Test
    func testEndingBalanceAndConversions() async throws {
        let rec = makeReconciliation(endingBalance: 200.50)
        #expect(rec.endingBalance == 200.50)
        #expect(rec.endingBalanceInGBP == 200.50)
        #expect(rec.newBalanceInGBP == 200.50)
    }

    @Test
    func testIsAnOpeningBalanceWithSentinelDate() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let sentinel = calendar.date(from: DateComponents(year: 1, month: 1, day: 2))!
        let rec = makeReconciliation(statementDate: sentinel.addingTimeInterval(-60))
        #expect(rec.isAnOpeningBalance == true)
    }

    // MARK: --- Functional Method Tests
    @Test
    func testCanReopenAccountingPeriodWithNoLaterClosed() async throws {
        let rec = makeReconciliation()
        #expect(rec.canReopenAccountingPeriod(in: context) == true)
    }

    func testCanCloseAccountingPeriodRequiresGapZeroAndValid() async throws {
        // Create previous reconciliation (closed)
        let previous = makeReconciliation(month: 9, endingBalance: 100, closed: true)
        
        // Current reconciliation
        let rec = makeReconciliation(month: 10, endingBalance: 100)
        
        // Add transactions to match endingBalance
        _ = makeTransaction(reconciliation: rec, amount: 50)
        _ = makeTransaction(reconciliation: rec, amount: 50)
        
        #expect(rec.canCloseAccountingPeriod(in: context) == true)
    }

    @Test
    func testCanDeleteClosedReturnsFalse() async throws {
        // Previous reconciliation (closed)
        let previous = makeReconciliation(month: 9, endingBalance: 100, closed: true)
        
        // Current reconciliation (closed)
        let rec = makeReconciliation(month: 10, endingBalance: 100, closed: true)
        
        #expect(rec.canDelete(in: context) == false)
    }

    @Test
    func testReconciliationGapCalculatesCorrectly() async throws {
        let rec = makeReconciliation(endingBalance: 100)
        
        // Transactions within reconciliation period
        _ = makeTransaction(reconciliation: rec, amount: 50, date: rec.transactionStartDate, closed: false)
        _ = makeTransaction(reconciliation: rec, amount: 50, date: rec.transactionStartDate, closed: false)
        
        #expect(rec.reconciliationGap(in: context) == 0)
    }

    @Test
    func testCloseAndReopenTransactions() async throws {
        let rec = makeReconciliation()
        
        // Transaction within reconciliation period
        let tx = makeTransaction(
            reconciliation: rec,
            amount: 50,
            date: rec.transactionStartDate,
            closed: false
        )
        
        try rec.close(in: context)
        #expect(rec.isClosed == true)
        #expect(tx.closed == true)
        
        try rec.reopen(in: context)
        #expect(rec.isClosed == false)
        #expect(tx.closed == false)
    }


    @Test
    func testTransactionsTotalInGBPSumsAmounts() async throws {
        let rec = makeReconciliation()
        
        _ = makeTransaction(reconciliation: rec, amount: 10, date: rec.transactionStartDate)
        _ = makeTransaction(reconciliation: rec, amount: 15, date: rec.transactionStartDate)
        
        #expect(try rec.transactionsTotalInGBP(in: context) == 25)
    }

    // MARK: --- Fetch Helpers Tests
    @Test
    func testFetchPreviousReturnsNilIfNone() async throws {
        // Create a reconciliation dated in the future
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let rec = makeReconciliation(statementDate: futureDate)
        let prev = try Reconciliation.fetchPrevious(for: rec.account, before: Date(), context: context)
        #expect(prev == nil)
    }

    @Test
    func testMakePeriodKeyGeneratesCorrectFormat() async throws {
        let key = Reconciliation.makePeriodKey(year: 2025, month: 7, paymentMethod: .VISA)
        #expect(key == "2025-07-VISA")
    }

    // MARK: --- Edge Case Tests
    @Test
    func testCanCloseAccountingPeriodFailsIfGapNotZero() async throws {
        let rec = makeReconciliation(endingBalance: 50)
        _ = makeTransaction(reconciliation: rec, amount: 60) // gap = 10
        #expect(rec.canCloseAccountingPeriod(in: context) == false)
    }

    @Test
    func testCanCloseAccountingPeriodFailsIfPreviousNotClosed() async throws {
        let prev = makeReconciliation(month: 9, closed: false)
        let rec = makeReconciliation(month: 10)
        #expect(rec.canCloseAccountingPeriod(in: context) == false)
    }

    @Test
    func testPreviousBalanceInGBPReturnsZeroIfNoPrevious() async throws {
        let rec = makeReconciliation()
        #expect(rec.previousBalanceInGBP == 0)
    }

    @Test
    func testPreviousBalanceInGBPReturnsCorrectValue() async throws {
        let prev = makeReconciliation(month: 9, endingBalance: 120)
        let rec = makeReconciliation(month: 10)
        #expect(rec.previousBalanceInGBP == 120)
    }

    @Test
    func testIsValidReturnsFalseIfTransactionInvalid() async throws {
        let rec = makeReconciliation()
        
        // Transaction inside reconciliation period
        let tx = Transaction(context: context)
        tx.txAmount = -10   // invalid
        tx.paymentMethodCD = rec.paymentMethodCD
        tx.transactionDate = rec.transactionStartDate
        tx.exchangeRate = 1
        
        try context.save()
        
        #expect(rec.isValid(in: context) == false)
    }

    @Test
    func testTransactionStartDateReturnsCorrectlyWithPrevious() async throws {
        let prev = makeReconciliation(month: 9, statementDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
        let rec = makeReconciliation(month: 10)
        let expectedStart = Calendar.current.date(byAdding: .day, value: 1, to: prev.statementDate!)!
        #expect(rec.transactionStartDate == expectedStart)
    }

    @Test
    func testTransactionStartDateReturnsDistantPastIfNoPrevious() async throws {
        let rec = makeReconciliation()
        #expect(rec.transactionStartDate == rec.statementDate)
    }

    @Test
    func testHasLaterReconciliationReturnsTrue() async throws {
        let rec1 = makeReconciliation(month: 9)
        let rec2 = makeReconciliation(month: 10)
        #expect(rec1.hasLaterReconciliation(in: context) == true)
    }

    @Test
    func testIsPreviousClosedReturnsTrueIfNoPrevious() async throws {
        let rec = makeReconciliation()
        #expect(rec.isPreviousClosed(in: context) == true)
    }

    @Test
    func testIsPreviousClosedReturnsCorrectlyIfPreviousClosed() async throws {
        let prev = makeReconciliation(month: 9, closed: true)
        let rec = makeReconciliation(month: 10)
        #expect(rec.isPreviousClosed(in: context) == true)
    }

    @Test
    func testIsPreviousClosedReturnsCorrectlyIfPreviousNotClosed() async throws {
        let prev = makeReconciliation(month: 9, closed: false)
        let rec = makeReconciliation(month: 10)
        #expect(rec.isPreviousClosed(in: context) == false)
    }
}
