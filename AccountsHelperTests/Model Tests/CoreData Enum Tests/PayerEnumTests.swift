//
//  PayerTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import Testing
@testable import AccountsHelper

struct PayerTests {

    @Test
    func testAllCasesUnique() async throws {
        let all = Payer.allCases
        let unique = Set(all.map(\.rawValue))
        #expect(all.count == unique.count)
        #expect(all.contains(.unknown))
        #expect(all.count == 4)
    }

    @Test
    func testRawValueAsString() async throws {
        for p in Payer.allCases {
            #expect(p.rawValueAsString() == String(p.rawValue))
        }
    }

    @Test
    func testDescription() async throws {
        #expect(Payer.tony.description == "Tony")
        #expect(Payer.yokko.description == "Yokko")
        #expect(Payer.ACHelper.description == "ACHelper")
        #expect(Payer.unknown.description == "Unknown")
    }

    @Test
    func testFromString() async throws {
        #expect(Payer.fromString("Tony") == .tony)
        #expect(Payer.fromString("Yokko") == .yokko)
        #expect(Payer.fromString("ACHelper") == .ACHelper)
        #expect(Payer.fromString("ANTHONY J STANNERS") == .tony)
        #expect(Payer.fromString("YOSHIKO STANNERS") == .yokko)
        #expect(Payer.fromString("UnknownName") == .unknown)
    }

    @Test
    func testFromIntAndInt32() async throws {
        #expect(Payer.fromInt(1) == .tony)
        #expect(Payer.fromInt(2) == .yokko)
        #expect(Payer.fromInt(98) == .ACHelper)
        #expect(Payer.fromInt(99) == .unknown)
        #expect(Payer.fromInt(100) == .unknown)

        #expect(Payer.fromInt32(1) == .tony)
        #expect(Payer.fromInt32(2) == .yokko)
        #expect(Payer.fromInt32(98) == .ACHelper)
        #expect(Payer.fromInt32(99) == .unknown)
        #expect(Payer.fromInt32(100) == .unknown)
    }

    @Test
    func testStringInitializer() async throws {
        #expect(Payer("Tony") == .tony)
        #expect(Payer("Yokko") == .yokko)
        #expect(Payer("XYZ") == .unknown)
    }

    @Test
    func testCodableRoundTrip() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for p in Payer.allCases {
            let data = try encoder.encode(p)
            let decoded = try decoder.decode(Payer.self, from: data)
            #expect(decoded == p)
        }
    }
}
