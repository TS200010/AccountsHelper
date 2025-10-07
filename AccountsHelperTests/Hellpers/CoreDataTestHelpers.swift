//  CoreDataTestHelpers.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import CoreData
@testable import AccountsHelper

final class CoreDataTestHelpers {

    /// Creates an in-memory NSPersistentContainer for testing
    static func makeInMemoryContainer() -> NSPersistentContainer {
        // Load the model from the app bundle
        guard let modelURL = Bundle(for: Transaction.self)
                .url(forResource: "AccountsHelperModel", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model from app bundle")
        }

        let container = NSPersistentContainer(name: "AccountsHelperModel", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }

        return container
    }

    /// Convenience: create a context
    static func makeInMemoryContext() -> NSManagedObjectContext {
        return makeInMemoryContainer().viewContext
    }
}
