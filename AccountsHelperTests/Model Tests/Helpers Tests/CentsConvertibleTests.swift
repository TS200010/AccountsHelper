import Foundation
import Testing
@testable import AccountsHelper

@MainActor
struct CentsConvertibleTests {

    // MARK: --- Mock type for testing
    struct MockCentsConverter: CentsConvertible {}

    // MARK: --- decimalToCents Tests

    @Test
    func testWholeNumber() async throws {
        let converter = MockCentsConverter()
        let result = converter.decimalToCents(Decimal(12))
        #expect(result == 1200)
    }

    @Test
    func testFractionalNumber() async throws {
        let converter = MockCentsConverter()
        let result = converter.decimalToCents(Decimal(string: "12.34")!)
        #expect(result == 1234)
    }

    @Test
    func testRoundingDown() async throws {
        let converter = MockCentsConverter()
        let result = converter.decimalToCents(Decimal(string: "12.345")!)
        #expect(result == 1235) // rounds to nearest
    }

    @Test
    func testRoundingUp() async throws {
        let converter = MockCentsConverter()
        let result = converter.decimalToCents(Decimal(string: "12.344")!)
        #expect(result == 1234) // rounds to nearest
    }

    @Test
    func testNegativeValue() async throws {
        let converter = MockCentsConverter()
        let result = converter.decimalToCents(Decimal(string: "-5.67")!)
        #expect(result == -567)
    }

    @Test
    func testZeroValue() async throws {
        let converter = MockCentsConverter()
        let result = converter.decimalToCents(Decimal(0))
        #expect(result == 0)
    }
}
