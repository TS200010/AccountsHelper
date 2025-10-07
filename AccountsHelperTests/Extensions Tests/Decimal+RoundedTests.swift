//
//  DecimalRoundedTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import Testing
@testable import AccountsHelper

struct DecimalRoundedTests {

    @Test
    func testRoundingHalfUp() async throws {
        let value: Decimal = 2.555
        let rounded = value.rounded(scale: 2, roundingMode: .plain)
        #expect(rounded == 2.56)
    }

    @Test
    func testRoundingDown() async throws {
        let value: Decimal = 2.559
        let rounded = value.rounded(scale: 2, roundingMode: .down)
        #expect(rounded == 2.55)
    }

    @Test
    func testRoundingUp() async throws {
        let value: Decimal = 2.551
        let rounded = value.rounded(scale: 2, roundingMode: .up)
        #expect(rounded == 2.56)
    }

    @Test
    func testRoundingZeroScale() async throws {
        let value: Decimal = 2.6
        let rounded = value.rounded(scale: 0, roundingMode: .plain)
        #expect(rounded == 3)
    }

    @Test
    func testNegativeValueRounding() async throws {
        let value: Decimal = -2.555
        let rounded = value.rounded(scale: 2, roundingMode: .plain)
        #expect(rounded == -2.56)
    }
}
