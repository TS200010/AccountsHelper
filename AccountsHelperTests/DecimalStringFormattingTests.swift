//  DecimalStringFormattingTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import Foundation
import Testing
@testable import AccountsHelper

struct DecimalStringFormattingTests {

    @Test
    func testString2fFormatsCorrectly() async throws {
        let value: Decimal = 123.456
        #expect(value.string2f == "123.46")

        let negative: Decimal = -2.555
        #expect(negative.string2f == "-2.56")

        let zero: Decimal = 0
        #expect(zero.string2f == "0.00")
    }

    @Test
    func testString0fFormatsCorrectly() async throws {
        let value: Decimal = 123.456
        #expect(value.string0f == "123")

        let negative: Decimal = -2.555
        #expect(negative.string0f == "-3")

        let zero: Decimal = 0
        #expect(zero.string0f == "0")
    }
}
