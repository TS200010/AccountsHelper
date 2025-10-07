//
//  CurrencyTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import Testing
@testable import AccountsHelper

struct CurrencyTests {

    @Test
    func testAllCasesUnique() async throws {
        let all = Currency.allCases
        let unique = Set(all.map(\.rawValue))
        #expect(all.count == unique.count)
        #expect(all.contains(.unknown))
        #expect(all.count == 5)
    }

    @Test
    func testRawValueAsString() async throws {
        for c in Currency.allCases {
            #expect(c.rawValueAsString() == String(c.rawValue))
        }
    }

    @Test
    func testDescription() async throws {
        #expect(Currency.GBP.description == "GBP")
        #expect(Currency.USD.description == "USD")
        #expect(Currency.JPY.description == "JPY")
        #expect(Currency.EUR.description == "EUR")
        #expect(Currency.unknown.description == "Unknown")
    }

    @Test
    func testFromString() async throws {
        #expect(Currency.fromString("GBP") == .GBP)
        #expect(Currency.fromString("USD") == .USD)
        #expect(Currency.fromString("JPY") == .JPY)
        #expect(Currency.fromString("JAPANESE YEN") == .JPY)
        #expect(Currency.fromString("JAPANESEYEN") == .JPY)
        #expect(Currency.fromString("EUR") == .EUR)
        #expect(Currency.fromString("XYZ") == .unknown)
    }

    @Test
    func testFromIntAndInt32() async throws {
        #expect(Currency.fromInt(1) == .GBP)
        #expect(Currency.fromInt(2) == .USD)
        #expect(Currency.fromInt(3) == .JPY)
        #expect(Currency.fromInt(4) == .EUR)
        #expect(Currency.fromInt(99) == .unknown)
        #expect(Currency.fromInt(123) == .unknown)

        #expect(Currency.fromInt32(1) == .GBP)
        #expect(Currency.fromInt32(2) == .USD)
        #expect(Currency.fromInt32(3) == .JPY)
        #expect(Currency.fromInt32(4) == .EUR)
        #expect(Currency.fromInt32(99) == .unknown)
        #expect(Currency.fromInt32(123) == .unknown)
    }

    @Test
    func testStringInitializer() async throws {
        #expect(Currency("GBP") == .GBP)
        #expect(Currency("JPY") == .JPY)
        #expect(Currency("EUR") == .EUR)
        #expect(Currency("UnknownValue") == .unknown)
    }

    @Test
    func testCodableRoundTrip() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for c in Currency.allCases {
            let data = try encoder.encode(c)
            let decoded = try decoder.decode(Currency.self, from: data)
            #expect(decoded == c)
        }
    }
}
