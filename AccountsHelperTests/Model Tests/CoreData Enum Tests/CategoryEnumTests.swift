//
//  CategoryTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import Testing
@testable import AccountsHelper

struct CategoryTests {

    @Test
    func testAllCasesUnique() async throws {
        let all = Category.allCases
        let unique = Set(all.map(\.rawValue))
        #expect(all.count == unique.count)
        #expect(all.contains(.unknown))
    }

    @Test
    func testRawValueAsString() async throws {
        for c in Category.allCases {
            #expect(c.rawValueAsString() == String(c.rawValue))
        }
    }

    @Test
    func testDescriptionsAreNonEmptyAndUnique() async throws {
        let descriptions = Category.allCases.map(\.description)
        #expect(descriptions.allSatisfy { !$0.isEmpty })
        let unique = Set(descriptions)
        #expect(descriptions.count == unique.count)
    }

    @Test
    func testSpecificDescriptions() async throws {
        #expect(Category.YPension.description == "Y Pension")
        #expect(Category.GardenHome.description == "GardenHome")
        #expect(Category.CarTax.description == "CarTax")
        #expect(Category.CompOfficeAV.description == "OfficeCompAV")
        #expect(Category.AMEXPatment.description == "AMEXPatment")
        #expect(Category.unknown.description == "Unknown")
    }

    @Test
    func testRawValuesAreConsistent() async throws {
        #expect(Category.YPension.rawValue == 1)
        #expect(Category.CouncilTax.rawValue == 28)
        #expect(Category.ToYokko.rawValue == 50)
        #expect(Category.ToAJBell.rawValue == 51)
        #expect(Category.AMEXPatment.rawValue == 58)
        #expect(Category.OpeningBalance.rawValue == 98)
        #expect(Category.unknown.rawValue == 999)
    }

    @Test
    func testCodableRoundTrip() async throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for c in Category.allCases {
            let data = try encoder.encode(c)
            let decoded = try decoder.decode(Category.self, from: data)
            #expect(decoded == c)
        }
    }

    @Test
    func testIdMatchesRawValue() async throws {
        for c in Category.allCases {
            #expect(c.id == c.rawValue)
        }
    }
}
