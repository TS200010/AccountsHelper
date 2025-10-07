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
        let all = PaymentMethod.allCases
        let unique = Set(all.map(\.rawValue))
        #expect(all.count == unique.count)
        #expect(all.contains(.unknown))
        #expect(all.count == 9)
    }

    @Test
    func testRawValueAsString() async throws {
        for method in PaymentMethod.allCases {
            #expect(method.rawValueAsString() == String(method.rawValue))
        }
    }

    @Test
    func testDescription() async throws {
        #expect(PaymentMethod.CashGBP.description == "Cash GBP")
        #expect(PaymentMethod.CashUSD.description == "Cash USD")
        #expect(PaymentMethod.CashEUR.description == "Cash EUR")
        #expect(PaymentMethod.CashYEN.description == "Cash YEN")
        #expect(PaymentMethod.AMEX.description == "AMEX")
        #expect(PaymentMethod.VISA.description == "VISA")
        #expect(PaymentMethod.BofSPV.description == "BofS PV")
        #expect(PaymentMethod.BofSCA.description == "BofS CA")
        #expect(PaymentMethod.unknown.description == "Unknown")
    }

    @Test
    func testCurrencyMapping() async throws {
        #expect(PaymentMethod.CashGBP.currency == .GBP)
        #expect(PaymentMethod.CashUSD.currency == .USD)
        #expect(PaymentMethod.CashEUR.currency == .EUR)
        #expect(PaymentMethod.CashYEN.currency == .JPY)
        #expect(PaymentMethod.AMEX.currency == .GBP)
        #expect(PaymentMethod.VISA.currency == .GBP)
        #expect(PaymentMethod.BofSPV.currency == .GBP)
        #expect(PaymentMethod.BofSCA.currency == .GBP)
        #expect(PaymentMethod.unknown.currency == .unknown)
    }

    @Test
    func testCodeMapping() async throws {
        #expect(PaymentMethod.CashGBP.code == "CASH_GBP")
        #expect(PaymentMethod.CashUSD.code == "CASH_USD")
        #expect(PaymentMethod.CashEUR.code == "CASH_EUR")
        #expect(PaymentMethod.CashYEN.code == "CASH_YEN")
        #expect(PaymentMethod.AMEX.code == "AMEX")
        #expect(PaymentMethod.VISA.code == "VISA")
        #expect(PaymentMethod.BofSPV.code == "BOFS_PV")
        #expect(PaymentMethod.BofSCA.code == "BOFS_CA")
        #expect(PaymentMethod.unknown.code == "UNKNOWN")
    }

    @Test
    func testFromIntAndInt32() async throws {
        #expect(PaymentMethod.fromInt(1) == .CashGBP)
        #expect(PaymentMethod.fromInt(2) == .CashUSD)
        #expect(PaymentMethod.fromInt(3) == .CashEUR)
        #expect(PaymentMethod.fromInt(4) == .CashYEN)
        #expect(PaymentMethod.fromInt(5) == .AMEX)
        #expect(PaymentMethod.fromInt(6) == .VISA)
        #expect(PaymentMethod.fromInt(7) == .BofSPV)
        #expect(PaymentMethod.fromInt(8) == .BofSCA)
        #expect(PaymentMethod.fromInt(99) == .unknown)
        #expect(PaymentMethod.fromInt(999) == .unknown)

        #expect(PaymentMethod.fromInt32(1) == .CashGBP)
        #expect(PaymentMethod.fromInt32(2) == .CashUSD)
        #expect(PaymentMethod.fromInt32(3) == .CashEUR)
        #expect(PaymentMethod.fromInt32(4) == .CashYEN)
        #expect(PaymentMethod.fromInt32(5) == .AMEX)
        #expect(PaymentMethod.fromInt32(6) == .VISA)
        #expect(PaymentMethod.fromInt32(7) == .BofSPV)
        #expect(PaymentMethod.fromInt32(8) == .BofSCA)
        #expect(PaymentMethod.fromInt32(999) == .unknown)
    }

    @Test
    func testCodableRoundTrip() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for method in PaymentMethod.allCases {
            let data = try encoder.encode(method)
            let decoded = try decoder.decode(PaymentMethod.self, from: data)
            #expect(decoded == method)
        }
    }
}
