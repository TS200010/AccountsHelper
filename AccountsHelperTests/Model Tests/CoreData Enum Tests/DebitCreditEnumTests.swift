//
//  DebitCreditTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import Testing
@testable import AccountsHelper

struct DebitCreditTests {

    @Test
    func testAllCasesAreUnique() async throws {
        let all = DebitCredit.allCases
        let unique = Set(all.map(\.rawValue))
        #expect(all.count == unique.count)
        #expect(all.contains(.unknown))
        #expect(all.count == 3)
    }

    @Test
    func testRawValueAsString() async throws {
        #expect(DebitCredit.DR.rawValueAsString() == "DR")
        #expect(DebitCredit.CR.rawValueAsString() == "CR")
        #expect(DebitCredit.unknown.rawValueAsString() == "Unknown")
    }

    @Test
    func testDescription() async throws {
        #expect(DebitCredit.DR.description == "DR")
        #expect(DebitCredit.CR.description == "CR")
        #expect(DebitCredit.unknown.description == "Unknown")
    }

    @Test
    func testFromIntAndInt32() async throws {
        #expect(DebitCredit.fromInt(1) == .DR)
        #expect(DebitCredit.fromInt(2) == .CR)
        #expect(DebitCredit.fromInt(123) == .unknown)

        #expect(DebitCredit.fromInt32(1) == .DR)
        #expect(DebitCredit.fromInt32(2) == .CR)
        #expect(DebitCredit.fromInt32(999) == .unknown)
    }

    @Test
    func testCodableRoundTrip() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for dc in DebitCredit.allCases {
            let data = try encoder.encode(dc)
            let decoded = try decoder.decode(DebitCredit.self, from: data)
            #expect(decoded == dc)
        }
    }
}
