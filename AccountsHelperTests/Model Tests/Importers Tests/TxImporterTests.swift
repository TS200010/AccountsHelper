import Foundation
import CoreData
import Testing
@testable import AccountsHelper

// MARK: --- Mock Importer for Testing
struct MockImporter: TxImporter {
    static var displayName: String = "Mock"
    static var paymentMethod: PaymentMethod = .CashGBP
    static var importType: ImportType = .csv

    @MainActor
    static func importTransactions(
        fileURL: URL,
        context: NSManagedObjectContext,
        mergeHandler: (Transaction, Transaction) async -> Transaction
    ) async -> [Transaction] {
        return []
    }
}

// Adapter to allow NSManagedObject Transaction with findMergeCandidateInSnapshot
extension MockImporter {
    static func findMergeCandidateInSnapshot(newTx: Transaction, snapshot: [Transaction]) -> Transaction? {
        for existing in snapshot {
            guard existing.txAmount == newTx.txAmount,
                  existing.paymentMethod == newTx.paymentMethod,
                  let existingDate = existing.transactionDate,
                  let newDate = newTx.transactionDate else {
                continue
            }

            let minDate = Calendar.current.date(byAdding: .day, value: -7, to: newDate)!
            let maxDate = Calendar.current.date(byAdding: .day, value: 1, to: newDate)!

            if existingDate >= minDate && existingDate <= maxDate {
                return existing
            }
        }
        return nil
    }
}

// MARK: --- TxImporter Tests
@MainActor
struct TxImporterTests {

    // MARK: --- CSV Parsing Tests

    @Test
    func testParseCSVSimple() async throws {
        let csv = "Name,Amount\nAlice,100\nBob,200"
        let rows = MockImporter.parseCSV(csvData: csv)
        #expect(rows.count == 3)
        #expect(rows[0] == ["Name", "Amount"])
        #expect(rows[1] == ["Alice", "100"])
        #expect(rows[2] == ["Bob", "200"])
    }

    @Test
    func testParseCSVWithQuotesAndCommas() async throws {
        let csv = "Name,Note\n\"Alice, A.\",\"Line1\nLine2\""
        let rows = MockImporter.parseCSV(csvData: csv)
        #expect(rows.count == 2)
        #expect(rows[0] == ["Name", "Note"])
        #expect(rows[1] == ["Alice, A.", "Line1\nLine2"])
    }

    @Test
    func testParseCSVTrimsTrailingEmptyHeaders() async throws {
        let csv = "A,B,C,,\n1,2,3,,"
        let rows = MockImporter.parseCSV(csvData: csv)
        #expect(rows[0] == ["A", "B", "C"])
        #expect(rows[1] == ["1", "2", "3", ""])
    }

    // MARK: --- Merge Candidate Tests

    @Test
    func testFindMergeCandidateExactMatch() async throws {
        let context = CoreDataTestHelpers.makeInMemoryContext()
        let date = Date()

        let existing = Transaction(context: context)
        existing.txAmount = 100
        existing.paymentMethod = .CashGBP
        existing.transactionDate = date

        let snapshot = [existing]

        let newTx = Transaction(context: context)
        newTx.txAmount = 100
        newTx.paymentMethod = .CashGBP
        newTx.transactionDate = date

        let candidate = MockImporter.findMergeCandidateInSnapshot(newTx: newTx, snapshot: snapshot)
        #expect(candidate != nil)
        #expect(candidate?.txAmount == 100)
    }

    @Test
    func testFindMergeCandidateWithinDateRange() async throws {
        let context = CoreDataTestHelpers.makeInMemoryContext()
        let newDate = Date()
        let oldDate = Calendar.current.date(byAdding: .day, value: -3, to: newDate)!

        let existing = Transaction(context: context)
        existing.txAmount = 50
        existing.paymentMethod = .VISA
        existing.transactionDate = oldDate

        let snapshot = [existing]

        let newTx = Transaction(context: context)
        newTx.txAmount = 50
        newTx.paymentMethod = .VISA
        newTx.transactionDate = newDate

        let candidate = MockImporter.findMergeCandidateInSnapshot(newTx: newTx, snapshot: snapshot)
        #expect(candidate != nil)
        #expect(candidate?.txAmount == 50)
    }

    @Test
    func testFindMergeCandidateNoMatch() async throws {
        let context = CoreDataTestHelpers.makeInMemoryContext()
        let existing = Transaction(context: context)
        existing.txAmount = 10
        existing.paymentMethod = .CashGBP
        existing.transactionDate = Date()

        let snapshot = [existing]

        let newTx = Transaction(context: context)
        newTx.txAmount = 20
        newTx.paymentMethod = .VISA
        newTx.transactionDate = Date()

        let candidate = MockImporter.findMergeCandidateInSnapshot(newTx: newTx, snapshot: snapshot)
        #expect(candidate == nil)
    }

    // MARK: --- Temporary Context Tests

    @Test
    func testMakeTemporaryContextHasParent() async throws {
        let parent = CoreDataTestHelpers.makeInMemoryContext()
        let temp = MockImporter.makeTemporaryContext(parent: parent)
        #expect(temp.parent === parent)
        #expect(temp.concurrencyType == .mainQueueConcurrencyType)
    }
}
