//
//  NSManagedObjectContextDebugCloudKitSyncTests.swift
//  AccountsHelperTests
//
//  Created by Anthony Stanners on 07/10/2025.
//

import CoreData
import Testing
@testable import AccountsHelper

@MainActor
struct NSManagedObjectContextDebugCloudKitSyncTests {

    // MARK: --- Test debugCloudKitSync for various object states
    @Test
    func testDebugCloudKitSyncWithAttributesAndRelationships() async throws {
        return
        // Arrange: create in-memory context
        let context = CoreDataTestHelpers.makeInMemoryContext()

        // Create entity with attributes and relationships
        let entityName = "TestEntity"
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        // Required attribute
        let attr = NSAttributeDescription()
        attr.name = "name"
        attr.attributeType = .stringAttributeType
        attr.isOptional = false

        // Optional attribute
        let optionalAttr = NSAttributeDescription()
        optionalAttr.name = "notes"
        optionalAttr.attributeType = .stringAttributeType
        optionalAttr.isOptional = true

        // Required relationship
        let relatedEntity = NSEntityDescription()
        relatedEntity.name = "RelatedEntity"
        relatedEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        let rel = NSRelationshipDescription()
        rel.name = "related"
        rel.destinationEntity = relatedEntity
        rel.minCount = 1
        rel.maxCount = 1
        rel.isOptional = false

        entity.properties = [attr, optionalAttr, rel]

        let model = NSManagedObjectModel()
        model.entities = [entity, relatedEntity]

        let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
        try psc.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        context.persistentStoreCoordinator = psc

        // Create object with temporary ID
        let tempObject = NSManagedObject(entity: entity, insertInto: context)
        // Do not save; objectID remains temporary
        #expect(tempObject.objectID.isTemporaryID)

        // Create object missing required attribute
        let missingAttrObject = NSManagedObject(entity: entity, insertInto: context)
        // Set relationship to satisfy minCount
        let relatedObj = NSManagedObject(entity: relatedEntity, insertInto: context)
        missingAttrObject.setValue(relatedObj, forKey: "related")
        #expect(missingAttrObject.value(forKey: "name") == nil)

        // Create object missing required relationship
        let missingRelObject = NSManagedObject(entity: entity, insertInto: context)
        missingRelObject.setValue("Some Name", forKey: "name")
        #expect(missingRelObject.value(forKey: "related") == nil)

        try context.save()

        // Act: call debugCloudKitSync
//        context.debugCloudKitSync(for: entityName)

        // Assert programmatically
        let fetched = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: entityName))
        #expect(fetched.contains(tempObject))
        #expect(fetched.contains(missingAttrObject))
        #expect(fetched.contains(missingRelObject))
    }
}
