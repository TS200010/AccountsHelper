import XCTest
import CoreData
@testable import AccountsHelper

final class PersistenceControllerTests: XCTestCase {

    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        container = {
            // Load model from the bundle explicitly
            guard let modelURL = Bundle(for: Transaction.self)
                    .url(forResource: "AccountsHelperModel", withExtension: "momd"),
                  let model = NSManagedObjectModel(contentsOf: modelURL) else {
                fatalError("Failed to load Core Data model")
            }
            let container = NSPersistentContainer(name: "AccountsHelperModel", managedObjectModel: model)
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]

            container.loadPersistentStores { storeDescription, error in
                if let error = error {
                    fatalError("Failed to load store: \(error)")
                }
            }
            return container
        }()

        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    func testInMemoryContainerIsEmptyInitially() async throws {
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        let results = try await self.context.perform {
            try self.context.fetch(fetchRequest)
        }
        XCTAssertEqual(results.count, 0, "In-memory store should start empty")
    }
}
