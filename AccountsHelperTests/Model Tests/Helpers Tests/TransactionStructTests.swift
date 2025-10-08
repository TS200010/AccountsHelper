//
//  TransactionStructTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import Testing
import CoreData

@testable import AccountsHelper

@MainActor
struct TransactionStructTests {

    // MARK: --- Helper to create default TransactionStruct
    private func makeDefaultTransaction() -> TransactionStruct {
        TransactionStruct(
            accountNumber: "12345",
            address: "1 Test St",
            category: .FoodHousehold,
            currency: .GBP,
            debitCredit: .DR,
            exchangeRate: 1.0,
            explanation: "Groceries",
            extendedDetails: "Tesco",
            payee: "Tesco",
            payer: .tony,
            paymentMethod: .CashGBP,
            reference: "Ref123",
            splitAmount: 10,
            splitCategory: .MiscOther,
            txAmount: 50,
            timestamp: Date(),
            transactionDate: Date(),
            commissionAmount: 2.5
        )
    }

    // MARK: --- Initialization Tests

    @Test
    func testDefaultInitializer() async throws {
        let tx = TransactionStruct()
        #expect(tx.category == .unknown)
        #expect(tx.currency == .GBP)
        #expect(tx.debitCredit == .DR)
        #expect(tx.exchangeRate == 1.0)
        #expect(tx.txAmount == 0)
    }

    @Test
    func testCustomInitializer() async throws {
        let tx = makeDefaultTransaction()
        #expect(tx.category == .FoodHousehold)
        #expect(tx.splitCategory == .MiscOther)
        #expect(tx.txAmount == 50)
        #expect(tx.splitAmount == 10)
        #expect(tx.totalInGBP == 52.5) // 50*1 + 2.5
        #expect(tx.isSplit)
    }

    @Test
    func testInitializerFromCoreData() async throws {
        let context = CoreDataTestHelpers.makeInMemoryContext()
        let cdTx = Transaction(context: context)
        cdTx.txAmount = 100
        cdTx.category = .Travel
        cdTx.splitAmount = 25
        cdTx.splitCategory = .MiscOther
        cdTx.exchangeRate = 1.2
        cdTx.commissionAmount = 3.0

        let tx = TransactionStruct(from: cdTx)
        #expect(tx.txAmount == 100)
        #expect(tx.category == .Travel)
        #expect(tx.splitAmount == 25)
        #expect(tx.splitCategory == .MiscOther)
        #expect(tx.totalInGBP == 123.0)
    }

    // MARK: --- Reset Tests

    @Test
    func testReset() async throws {
        var tx = makeDefaultTransaction()
        tx.setDefaults()
        #expect(tx.txAmount == 0)
        #expect(tx.category == .unknown)
        #expect(tx.splitCategory == .unknown)
        #expect(tx.currency == .GBP)
        #expect(tx.debitCredit == .DR)
        #expect(tx.exchangeRate == 1.0)
        #expect(tx.splitAmount == 0)
        #expect(tx.payee == "")
        #expect(tx.payer == .tony)
        #expect(tx.paymentMethod == .AMEX)
    }

    // MARK: --- Apply Tests

    @Test
    func testApplyToCoreData() async throws {
        let txStruct = makeDefaultTransaction()
        let context = CoreDataTestHelpers.makeInMemoryContext()
        let cdTx = Transaction(context: context)
        txStruct.apply(to: cdTx)

        #expect(cdTx.txAmount == 50)
        #expect(cdTx.category == .FoodHousehold)
        #expect(cdTx.splitAmount == 10)
        #expect(cdTx.splitCategory == .MiscOther)
//        #expect(cdTx.totalInGBP == 52.5)
        #expect(cdTx.payee == "Tesco")
        #expect(cdTx.payer == .tony)
    }

    // MARK: --- Derived Property Tests

    @Test
    func testSplitRemainder() async throws {
        let tx = TransactionStruct(category: .Travel, splitAmount: 30, splitCategory: .MiscOther, txAmount: 100)
        #expect(tx.splitRemainderAmount == 70)
        #expect(tx.splitRemainderCategory == .Travel)
    }

    @Test
    func testIsSplit() async throws {
        let tx1 = TransactionStruct(splitAmount: 0, txAmount: 50)
        #expect(!tx1.isSplit)

        let tx2 = TransactionStruct(splitAmount: 10, txAmount: 50)
        #expect(tx2.isSplit)
    }

    @Test
    func testTotalInGBP() async throws {
        let tx = TransactionStruct(exchangeRate: 1.1, txAmount: 100, commissionAmount: 5)
        #expect(tx.totalInGBP == 115)
    }
}
