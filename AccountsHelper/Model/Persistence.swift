//
//  Persistence.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import CoreData

final class PersistenceController {
    
    static let shared = PersistenceController()
    
    private var remoteChangeObserver: NSObjectProtocol?
    
    // MARK: - Remote change handler
    private func handleRemoteChange(_ notification: Notification) {
        print("🔄 Remote change received — updating UI")
        let context = container.viewContext
        context.perform {
            NotificationCenter.default.post(
                name: Notification.Name("AccountsHelperRemoteChange"),
                object: nil
            )
        }
    }

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
//            let newItem = Item(context: viewContext)
//            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        
        UserDefaults.standard.set(true, forKey: "com.apple.CoreData.CloudKitDebug")

        container = NSPersistentCloudKitContainer(name: "AccountsHelperModel") // CoreData model name

        if gUseLiveStore {
            if let storeDescription = container.persistentStoreDescriptions.first {
                storeDescription.cloudKitContainerOptions =
                NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.ItMk.AccountsHelper.live")
            }
        } else {
            if let storeDescription = container.persistentStoreDescriptions.first {
                storeDescription.cloudKitContainerOptions =
                NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.ItMk.AccountsHelper.dev")
            }
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Add notifications so we sync quickly with iCloud
        remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] notification in
            self?.handleRemoteChange(notification)
        }
//        ) { notification in
//            print("🔄 Remote change received: \(notification)")
//        }
        
//        let newTransaction = Transaction(context: container.viewContext)
//        newTransaction.timestamp = Date()
////        try? container.viewContext.save()
//        
//        container.viewContext.performAndWait {
//            do {
//                try container.viewContext.save()
//                print("💾 Mac record saved locally, should be pushed")
//            } catch {
//                print("❌ Failed to save: \(error)")
//            }
//        }
//        
//        container.viewContext.refreshAllObjects() // optional

//        container.persistentStoreCoordinator
//            .persistentStores
//            .forEach { store in
//                if let ckStore = store as? NSPersistentCloudKitContainerOptions {
//                    // No direct access needed; just touching the context triggers push
//                    container.viewContext.refreshAllObjects()
//                }
//            }
        
        
#if DEBUG
        if gUploadSchema {
            do {
                try container.initializeCloudKitSchema(options: [])
                print("✅ CloudKit schema initialized")
            } catch {
                print("❌ Failed to initialize CloudKit schema: \(error)")
            }
        }
#endif
        
#if DEBUG
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            print("CoreData SQLite file is at: \(storeURL.path)")
        }
#endif
        
        

        /*
        // Loads xcdatatamodeld file
        container = NSPersistentCloudKitContainer(name: "AccountsHelper")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Now set up CloudKit
        if let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.AccountsHelper"  // Use the exact string from Xcode
            )
        }

        // Load the persistent stores
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
         */
    }
    
    deinit {
        if let observer = remoteChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
