//
//  TransactionValidatableTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import Testing
@testable import AccountsHelper

@MainActor
struct TransactionValidatableTests {
    
    // MARK: --- Helper Struct
    /// Simple struct conforming to TransactionValidatable for testing purposes
    struct MockTransaction: TransactionValidatable {
        var txAmount: Decimal = 100
        var category: AccountsHelper.Category = .FoodHousehold
        var currency: Currency = .GBP
        var debitCredit: DebitCredit = .DR
        var exchangeRate: Decimal = 1.0
        var payee: String? = "Tesco"
        var payer: Payer = .tony
        var account: ReconcilableAccounts = .CashGBP
        var splitRemainderCategory: AccountsHelper.Category = .FoodHousehold
        var transactionDate: Date? = Date()
        
        var splitCategory: AccountsHelper.Category = .MiscOther
        var splitAmount: Decimal = 50
    }
    
    // MARK: --- Valid Transaction Test
    @Test
    func testValidTransaction() async throws {
        let tx = MockTransaction()
        #expect(tx.isValid())
    }
    
    // MARK: --- Invalid Amount Test
    @Test
    func testInvalidAmount() async throws {
        var tx = MockTransaction()
        tx.txAmount = 0
        #expect(!tx.isTXAmountValid())
        #expect(!tx.isValid())
    }
    
    // MARK: --- Invalid Category Test
    @Test
    func testInvalidCategory() async throws {
        var tx = MockTransaction()
        tx.category = .unknown
        #expect(!tx.isCategoryValid())
        #expect(!tx.isValid())
    }
    
    // MARK: --- Invalid Currency Test
    @Test
    func testInvalidCurrency() async throws {
        var tx = MockTransaction()
        tx.currency = .unknown
        #expect(!tx.isCurrencyValid())
        #expect(!tx.isValid())
    }
    
    // MARK: --- Invalid Exchange Rate Test
    @Test
    func testInvalidExchangeRate() async throws {
        var tx = MockTransaction()
        tx.currency = .USD
        tx.exchangeRate = 0
        #expect(!tx.isExchangeRateValid())
        #expect(!tx.isValid())
    }
    
    // MARK: --- Invalid DebitCredit Test
    @Test
    func testInvalidDebitCredit() async throws {
        var tx = MockTransaction()
        tx.debitCredit = .unknown
        #expect(!tx.isDebitCreditValid())
        #expect(!tx.isValid())
    }
    
    // MARK: --- Invalid Payer Test
    @Test
    func testInvalidPayer() async throws {
        var tx = MockTransaction()
        tx.payer = .unknown
        #expect(!tx.isPayerValid())
        #expect(!tx.isValid())
    }
    
    // MARK: --- Invalid Payment Method Test
    @Test
    func testInvalidPaymentMethod() async throws {
        var tx = MockTransaction()
        tx.account = .unknown
        #expect(!tx.isAccountValid())
        #expect(!tx.isValid())
    }
    
    // MARK: --- Invalid Split Amount Test
    @Test
    func testInvalidSplitAmount() async throws {
        var tx = MockTransaction()
        tx.splitAmount = 150 // greater than total txAmount
        #expect(!tx.isSplitAmountValid())
    }
    
    // MARK: --- Invalid Split Category Test
    @Test
    func testInvalidSplitCategory() async throws {
        var tx = MockTransaction()
        tx.splitCategory = .unknown
        #expect(!tx.isSplitCategoryValid())
    }
    
    // MARK: --- Invalid Split Remainder Category Test
    @Test
    func testInvalidSplitRemainderCategory() async throws {
        var tx = MockTransaction()
        tx.splitRemainderCategory = .unknown
        #expect(!tx.isSplitRemainderCategoryValid())
    }
    
    // MARK: --- Invalid Transaction Date Test
    @Test
    func testInvalidTransactionDate() async throws {
        var tx = MockTransaction()
        tx.transactionDate = Date().addingTimeInterval(60*60*24) // future date
        #expect(!tx.isTransactionDateValid())
        #expect(!tx.isValid())
    }
}


