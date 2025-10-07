//
//  Persistence.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import CoreData

/*
    ────────────────────────────────────────────────────────────────
    PersistenceController
    • Manages the Core Data stack (local + CloudKit)
    • Handles in-memory mode for testing
    • Observes remote iCloud Core Data changes
    • Initializes CloudKit schema when requested in DEBUG mode
    ────────────────────────────────────────────────────────────────
*/

final class PersistenceController {
    
    // MARK: --- Shared Singleton
    static let shared = PersistenceController()
    
    // MARK: --- Properties
    let container: NSPersistentCloudKitContainer
    private var remoteChangeObserver: NSObjectProtocol?
    
    // MARK: --- Initializer
    init(inMemory: Bool = false) {
        
        // Enable CoreData + CloudKit debugging
        UserDefaults.standard.set(true, forKey: "com.apple.CoreData.CloudKitDebug")
        
        // Create container with model name
        container = NSPersistentCloudKitContainer(name: "AccountsHelperModel")
        
        // Configure CloudKit environment
        if gUseLiveStore {
            if let storeDescription = container.persistentStoreDescriptions.first {
                storeDescription.cloudKitContainerOptions =
                    NSPersistentCloudKitContainerOptions(
                        containerIdentifier: "iCloud.ItMk.AccountsHelper.live"
                    )
            }
        } else {
            if let storeDescription = container.persistentStoreDescriptions.first {
                storeDescription.cloudKitContainerOptions =
                    NSPersistentCloudKitContainerOptions(
                        containerIdentifier: "iCloud.ItMk.AccountsHelper.dev"
                    )
            }
        }
        
        // Load persistent stores
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("❌ Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Merge settings
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Observe iCloud remote changes
        remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] notification in
            self?.handleRemoteChange(notification)
        }
        
        // Optional: Initialize CloudKit schema in DEBUG mode
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
        
        // Optional: Log SQLite store path
        #if DEBUG
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            print("📁 CoreData SQLite file is at: \(storeURL.path)")
        }
        #endif
    }
    
    // MARK: --- Remote Change Handler
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
    
    // MARK: --- Deinitializer
    deinit {
        if let observer = remoteChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
