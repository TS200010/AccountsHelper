//
//  TransactionExtensionsTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import CoreData
import Testing
@testable import AccountsHelper

@MainActor
struct TransactionExtensionsTests {

    // MARK: --- Helpers

    private func makeTransaction(
        amount: Decimal = 100,
        splitAmount: Decimal = 40,
        commission: Decimal = 5,
        currency: Currency = .GBP,
        paymentMethod: PaymentMethod = .VISA,
        date: Date = Date(),
        context: NSManagedObjectContext
    ) -> Transaction {
        let tx = Transaction(context: context)
        tx.txAmount = amount
        tx.splitAmount = splitAmount
        tx.commissionAmount = commission
        tx.currency = currency
        tx.paymentMethod = paymentMethod
        tx.transactionDate = date
        try? context.save()
        return tx
    }

    private var context: NSManagedObjectContext {
        CoreDataTestHelpers.makeInMemoryContext()
    }

    // MARK: --- Computed Properties

    @Test
    func testSplitAmountInGBPCalculatesCorrectly() async throws {
        let tx = makeTransaction(amount: 100, splitAmount: 50, commission: 5, currency: .GBP, context: context)
        #expect(tx.splitAmountInGBP == Decimal(50 + 5))
    }

    @Test
    func testSplitRemainderAmountInGBPCalculatesCorrectly() async throws {
        let tx = makeTransaction(amount: 100, splitAmount: 40, currency: .GBP, context: context)
        #expect(tx.splitRemainderAmountInGBP == Decimal(60))
    }

    @Test
    func testTotalAmountInGBPSumsSplitAndRemainder() async throws {
        let tx = makeTransaction(amount: 200, splitAmount: 50, commission: 10, currency: .GBP, context: context)
        #expect(tx.totalAmountInGBP == Decimal(50 + 10 + 150))
    }

    @Test
    func testSplitAmountEdgeCases() async throws {
        let tx1 = makeTransaction(amount: 100, splitAmount: 0, commission: 0, context: context)
        #expect(tx1.splitAmountInGBP == 0)

        let tx2 = makeTransaction(amount: 100, splitAmount: 100, commission: 10, context: context)
        #expect(tx2.splitRemainderAmountInGBP == 0)
        #expect(tx2.totalAmountInGBP == Decimal(110))
    }

    // MARK: --- Exchange Rate

    @Test
    func testSplitAmountWithNonDefaultExchangeRate() async throws {
        let tx = makeTransaction(amount: 100, splitAmount: 50, commission: 5, currency: .USD, context: context)
        tx.exchangeRate = 2
        #expect(tx.splitAmountInGBP == Decimal(50)/2 + 5)
        #expect(tx.splitRemainderAmountInGBP == Decimal(50)/2)
    }

    @Test
    func testExchangeRateZeroDefaultsToOne() async throws {
        let tx = makeTransaction(amount: 100, context: context)
        tx.exchangeRate = 0
        #expect(tx.exchangeRate == 1)
    }

    // MARK: --- Currency Formatting

    @Test
    func testTxAmountAsStringForJPY() async throws {
        let tx = makeTransaction(amount: 1000, currency: .JPY, context: context)
        #expect(tx.txAmountAsString() == "1000")
    }

    @Test
    func testTxAmountAsStringForGBP() async throws {
        let tx = makeTransaction(amount: 123.45, currency: .GBP, context: context)
        #expect(tx.txAmountAsString() == "123.45")
    }

    @Test
    func testExchangeRateAsStringForDifferentCurrencies() async throws {
        let txGBP = makeTransaction(currency: .GBP, context: context)
        txGBP.exchangeRate = 123.45
        #expect(txGBP.exchangeRateAsString() == "123.45")

        let txJPY = makeTransaction(currency: .JPY, context: context)
        txJPY.exchangeRate = 1000
        #expect(txJPY.exchangeRateAsString() == "1000")
    }

    // MARK: --- TransactionStruct Matching

    @Test
    func testMatchCountAndHasMultipleMatches() async throws {

        // Arrange
        let context = CoreDataTestHelpers.makeInMemoryContext()
        let now = Date()

        // Create two identical transactions
        let tx1 = makeTransaction(amount: 100, currency: .GBP, paymentMethod: .VISA, date: now, context: context)
        let tx2 = makeTransaction(amount: 100, currency: .GBP, paymentMethod: .VISA, date: now, context: context)
        try context.save()

        // Verify both transactions exist
        let allTxs: [Transaction] = try context.fetch(Transaction.fetchRequest())
        print("All transactions in context: \(allTxs.count)")
        #expect(allTxs.count == 2)

        // Prepare TransactionStruct to compare against
        let temp = TransactionStruct( currency: .GBP, paymentMethod: .VISA, txAmount: 100,
            transactionDate: now
        )

        // Inline Decimal-to-Cents logic
        func cents(_ value: Decimal) -> Int64 {
            var rounded = Decimal()
            var mutable = value
            NSDecimalRound(&rounded, &mutable, 2, .plain)
            return NSDecimalNumber(decimal: rounded * 100).int64Value
        }

        // Step 1: Match by amount only
        let amountOnlyRequest = Transaction.fetchRequest()
        amountOnlyRequest.predicate = NSPredicate(format: "txAmountCD == %lld", cents(temp.txAmount))
        let countAmountOnly = try context.count(for: amountOnlyRequest)
        #expect(countAmountOnly == 2)

        // Step 2: Match by amount + currency
        let amountCurrencyRequest = Transaction.fetchRequest()
        amountCurrencyRequest.predicate = NSPredicate(
            format: "txAmountCD == %lld AND currencyCD == %d",
            cents(temp.txAmount),
            temp.currency.rawValue
        )
        let countAmountCurrency = try context.count(for: amountCurrencyRequest)
        #expect(countAmountCurrency == 2)

        // Step 3: Match by amount + currency + payment method
        let amountCurrencyPMRequest = Transaction.fetchRequest()
        amountCurrencyPMRequest.predicate = NSPredicate(
            format: "txAmountCD == %lld AND currencyCD == %d AND paymentMethodCD == %d",
            cents(temp.txAmount),
            temp.currency.rawValue,
            temp.paymentMethod.rawValue
        )
        let countAmountCurrencyPM = try context.count(for: amountCurrencyPMRequest)
        #expect(countAmountCurrencyPM == 2)

        // Step 4: Full match predicate including date range
        let fullRequest = Transaction.fetchRequest()
        let startDate = now.addingTimeInterval(-7 * 24 * 60 * 60)
        let endDate = now.addingTimeInterval(1 * 24 * 60 * 60)
        fullRequest.predicate = NSPredicate(
            format: "txAmountCD == %lld AND currencyCD == %d AND paymentMethodCD == %d AND transactionDate >= %@ AND transactionDate <= %@",
            cents(temp.txAmount),
            temp.currency.rawValue,
            temp.paymentMethod.rawValue,
            startDate as NSDate,
            endDate as NSDate
        )

        let fullCount = try context.count(for: fullRequest)
        #expect(fullCount == 2)

        // Step 5: Functional verification of helper method
        #expect(Transaction.hasMultipleMatches(for: temp, in: context) == true)
    }




    @Test
    func testMatchCountWithNoMatch() async throws {
        let temp = TransactionStruct(currency: .USD, paymentMethod: .VISA, txAmount: 999, transactionDate: Date())
        #expect(Transaction.matchCount(for: temp, in: context) == 0)
    }

    // MARK: --- Random Transaction Generator

    @Test
    func testGenerateRandomTransactionsProducesCorrectCountAndDateRange() async throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600*24*10)
        let txs = Transaction.generateRandomTransactions(for: .VISA, currency: .GBP, startDate: startDate, endDate: endDate, count: 10, in: context)
        #expect(txs.count == 10)
        for tx in txs {
            #expect(tx.transactionDate! >= startDate && tx.transactionDate! <= endDate)
        }
    }

    // MARK: --- Comparable Fields

    @Test
    func testComparableFieldsRepresentationExcludesIdAndTimestamp() async throws {
        let tx = makeTransaction(context: context)
        let repr = tx.comparableFieldsRepresentation()
        #expect(!repr.contains("id"))
        #expect(!repr.contains("timestamp"))
    }
}
