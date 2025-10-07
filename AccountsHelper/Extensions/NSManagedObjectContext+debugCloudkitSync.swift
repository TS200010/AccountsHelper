//
//  NSManagedObjectContext+debugCloudkitSync.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 26/09/2025.
//

import Foundation
import CoreData

// MARK: --- NSManagedObjectContext CloudKit Debugging
extension NSManagedObjectContext {
    
    /// Debug Core Data objects for a given entity, checking IDs, attributes, and relationships
    func XdebugCloudKitSync(for entityName: String) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)

        do {
            let objects = try self.fetch(fetchRequest)
            print("📦 \(entityName): Found \(objects.count) objects in Core Data")

            for obj in objects {
                if obj.objectID.isTemporaryID {
                    print("⚠️ Object \(obj) still has a temporary ID (not yet saved).")
                } else {
                    print("✅ ObjectID: \(obj.objectID)")
                }

                // Check required attributes
                let attributes = obj.entity.attributesByName
                for (key, _) in attributes {
                    let value = obj.value(forKey: key)
                    if value == nil {
                        print("   ⚠️ Missing value for attribute: \(key)")
                    }
                }

                // Check relationships
                let relationships = obj.entity.relationshipsByName
                for (relName, relDesc) in relationships {
                    let value = obj.value(forKey: relName)
                    if !relDesc.isOptional && value == nil {
                        print("   ❌ Missing required relationship: \(relName)")
                    }
                }
            }
        } catch {
            print("❌ Failed to fetch \(entityName): \(error)")
        }
    }
}
