//
//  AccountingPeriodTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import Testing
@testable import AccountsHelper

@MainActor
struct AccountingPeriodTests {

    // MARK: --- Display String Tests

    @Test
    func testDisplayStringRegularPeriod() async throws {
        let period = AccountingPeriod(year: 2025, month: 9)
        let result = period.displayString
        #expect(result.contains("2025"))
        #expect(result.contains("September") || result.contains("Sep")) // localized month name
    }

    @Test
    func testDisplayStringWithOpeningRegularPeriod() async throws {
        let period = AccountingPeriod(year: 2025, month: 9)
        let result = period.displayStringWithOpening
        #expect(result.contains("2025"))
        #expect(result.contains("September") || result.contains("Sep"))
    }

    @Test
    func testDisplayStringWithOpeningOpeningBalancesYear1() async throws {
        let period = AccountingPeriod(year: 1, month: 1)
        let result = period.displayStringWithOpening
        #expect(result == "Opening Balances")
    }

    @Test
    func testDisplayStringWithOpeningOpeningBalancesYear0() async throws {
        let period = AccountingPeriod(year: 0, month: 5)
        let result = period.displayStringWithOpening
        #expect(result == "Opening Balances")
    }

    // MARK: --- Hashable / Equality Tests

    @Test
    func testHashableEquality() async throws {
        let period1 = AccountingPeriod(year: 2025, month: 9)
        let period2 = AccountingPeriod(year: 2025, month: 9)
        let period3 = AccountingPeriod(year: 2025, month: 10)

        #expect(period1 == period2)
        #expect(period1 != period3)

        let set: Set<AccountingPeriod> = [period1, period2, period3]
        #expect(set.count == 2)
    }

    // MARK: --- Edge Cases

    @Test
    func testDisplayStringWithInvalidMonth() async throws {
        // Month > 12, should fallback
        let period = AccountingPeriod(year: 2025, month: 13)
        let result = period.displayStringWithOpening
        #expect(result == "December 2025")
    }

    @Test
    func testDisplayStringWithNegativeYear() async throws {
        let period = AccountingPeriod(year: -1, month: 5)
        let result = period.displayStringWithOpening
        #expect(result == "Opening Balances")
    }
}

