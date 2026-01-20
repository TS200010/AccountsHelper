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
        #expect(ReconcilableAccounts.CashGBP.description == "Cash GBP")
        #expect(ReconcilableAccounts.CashUSD.description == "Cash USD")
        #expect(ReconcilableAccounts.CashEUR.description == "Cash EUR")
        #expect(ReconcilableAccounts.CashYEN.description == "Cash YEN")
        #expect(ReconcilableAccounts.AMEX.description == "AMEX")
        #expect(ReconcilableAccounts.VISA.description == "VISA")
        #expect(ReconcilableAccounts.BofSPV.description == "BofS PV")
        #expect(ReconcilableAccounts.BofSCA.description == "BofS CA")
        #expect(ReconcilableAccounts.unknown.description == "Unknown")
    }

    @Test
    func testCurrencyMapping() async throws {
        #expect(ReconcilableAccounts.CashGBP.currency == .GBP)
        #expect(ReconcilableAccounts.CashUSD.currency == .USD)
        #expect(ReconcilableAccounts.CashEUR.currency == .EUR)
        #expect(ReconcilableAccounts.CashYEN.currency == .JPY)
        #expect(ReconcilableAccounts.AMEX.currency == .GBP)
        #expect(ReconcilableAccounts.VISA.currency == .GBP)
        #expect(ReconcilableAccounts.BofSPV.currency == .GBP)
        #expect(ReconcilableAccounts.BofSCA.currency == .GBP)
        #expect(ReconcilableAccounts.unknown.currency == .unknown)
    }

    @Test
    func testCodeMapping() async throws {
        #expect(ReconcilableAccounts.CashGBP.code == "CASH_GBP")
        #expect(ReconcilableAccounts.CashUSD.code == "CASH_USD")
        #expect(ReconcilableAccounts.CashEUR.code == "CASH_EUR")
        #expect(ReconcilableAccounts.CashYEN.code == "CASH_YEN")
        #expect(ReconcilableAccounts.AMEX.code == "AMEX")
        #expect(ReconcilableAccounts.VISA.code == "VISA")
        #expect(ReconcilableAccounts.BofSPV.code == "BOFS_PV")
        #expect(ReconcilableAccounts.BofSCA.code == "BOFS_CA")
        #expect(ReconcilableAccounts.unknown.code == "UNKNOWN")
    }

    @Test
    func testFromIntAndInt32() async throws {
        #expect(ReconcilableAccounts.fromInt(1) == .CashGBP)
        #expect(ReconcilableAccounts.fromInt(2) == .CashUSD)
        #expect(ReconcilableAccounts.fromInt(3) == .CashEUR)
        #expect(ReconcilableAccounts.fromInt(4) == .CashYEN)
        #expect(ReconcilableAccounts.fromInt(5) == .AMEX)
        #expect(ReconcilableAccounts.fromInt(6) == .VISA)
        #expect(ReconcilableAccounts.fromInt(7) == .BofSPV)
        #expect(ReconcilableAccounts.fromInt(8) == .BofSCA)
        #expect(ReconcilableAccounts.fromInt(99) == .unknown)
        #expect(ReconcilableAccounts.fromInt(999) == .unknown)

        #expect(ReconcilableAccounts.fromInt32(1) == .CashGBP)
        #expect(ReconcilableAccounts.fromInt32(2) == .CashUSD)
        #expect(ReconcilableAccounts.fromInt32(3) == .CashEUR)
        #expect(ReconcilableAccounts.fromInt32(4) == .CashYEN)
        #expect(ReconcilableAccounts.fromInt32(5) == .AMEX)
        #expect(ReconcilableAccounts.fromInt32(6) == .VISA)
        #expect(ReconcilableAccounts.fromInt32(7) == .BofSPV)
        #expect(ReconcilableAccounts.fromInt32(8) == .BofSCA)
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
