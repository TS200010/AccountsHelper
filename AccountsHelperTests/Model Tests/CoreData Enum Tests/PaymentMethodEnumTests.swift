//
//  PaymentMethodTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import Testing
@testable import AccountsHelper

struct PaymentMethodTests {

    @Test
    func testAllCasesUnique() async throws {
        let all = ReconcilableAccounts.allCases
        let unique = Set(all.map(\.rawValue))
        #expect(all.count == unique.count)
        #expect(all.contains(.unknown))
        #expect(all.count == 9)
    }

    @Test
    func testRawValueAsString() async throws {
        for method in ReconcilableAccounts.allCases {
            #expect(method.rawValueAsString() == String(method.rawValue))
        }
    }

    @Test
    func testDescription() async throws {
        #expect(ReconcilableAccounts.CashUKL.description == "Cash UKL")
        #expect(ReconcilableAccounts.CashUSD.description == "Cash USD")
        #expect(ReconcilableAccounts.CashEUR.description == "Cash EUR")
        #expect(ReconcilableAccounts.CashYEN.description == "Cash YEN")
        #expect(ReconcilableAccounts.AMEX.description == "AMEX")
        #expect(ReconcilableAccounts.VISA.description == "VISA")
        #expect(ReconcilableAccounts.BofSPV_82.description == "BofS PV")
        #expect(ReconcilableAccounts.BofSCA_64.description == "BofS CA")
        #expect(ReconcilableAccounts.unknown.description == "Unknown")
    }

    @Test
    func testCurrencyMapping() async throws {
        #expect(ReconcilableAccounts.CashUKL.currency == .UKL)
        #expect(ReconcilableAccounts.CashUSD.currency == .USD)
        #expect(ReconcilableAccounts.CashEUR.currency == .EUR)
        #expect(ReconcilableAccounts.CashYEN.currency == .JPY)
        #expect(ReconcilableAccounts.AMEX.currency == .UKL)
        #expect(ReconcilableAccounts.VISA.currency == .UKL)
        #expect(ReconcilableAccounts.BofSPV_82.currency == .UKL)
        #expect(ReconcilableAccounts.BofSCA_64.currency == .UKL)
        #expect(ReconcilableAccounts.unknown.currency == .unknown)
    }

    @Test
    func testCodeMapping() async throws {
        #expect(ReconcilableAccounts.CashUKL.code == "CASH_UKL")
        #expect(ReconcilableAccounts.CashUSD.code == "CASH_USD")
        #expect(ReconcilableAccounts.CashEUR.code == "CASH_EUR")
        #expect(ReconcilableAccounts.CashYEN.code == "CASH_YEN")
        #expect(ReconcilableAccounts.AMEX.code == "AMEX")
        #expect(ReconcilableAccounts.VISA.code == "VISA")
        #expect(ReconcilableAccounts.BofSPV_82.code == "BOFS_PV")
        #expect(ReconcilableAccounts.BofSCA_64.code == "BOFS_CA")
        #expect(ReconcilableAccounts.unknown.code == "UNKNOWN")
    }

    @Test
    func testFromIntAndInt32() async throws {
        #expect(ReconcilableAccounts.fromInt(1) == .CashUKL)
        #expect(ReconcilableAccounts.fromInt(2) == .CashUSD)
        #expect(ReconcilableAccounts.fromInt(3) == .CashEUR)
        #expect(ReconcilableAccounts.fromInt(4) == .CashYEN)
        #expect(ReconcilableAccounts.fromInt(5) == .AMEX)
        #expect(ReconcilableAccounts.fromInt(6) == .VISA)
        #expect(ReconcilableAccounts.fromInt(7) == .BofSPV_82)
        #expect(ReconcilableAccounts.fromInt(8) == .BofSCA_64)
        #expect(ReconcilableAccounts.fromInt(99) == .unknown)
        #expect(ReconcilableAccounts.fromInt(999) == .unknown)

        #expect(ReconcilableAccounts.fromInt32(1) == .CashUKL)
        #expect(ReconcilableAccounts.fromInt32(2) == .CashUSD)
        #expect(ReconcilableAccounts.fromInt32(3) == .CashEUR)
        #expect(ReconcilableAccounts.fromInt32(4) == .CashYEN)
        #expect(ReconcilableAccounts.fromInt32(5) == .AMEX)
        #expect(ReconcilableAccounts.fromInt32(6) == .VISA)
        #expect(ReconcilableAccounts.fromInt32(7) == .BofSPV_82)
        #expect(ReconcilableAccounts.fromInt32(8) == .BofSCA_64)
        #expect(ReconcilableAccounts.fromInt32(999) == .unknown)
    }

    @Test
    func testCodableRoundTrip() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for method in ReconcilableAccounts.allCases {
            let data = try encoder.encode(method)
            let decoded = try decoder.decode(ReconcilableAccounts.self, from: data)
            #expect(decoded == method)
        }
    }
}
