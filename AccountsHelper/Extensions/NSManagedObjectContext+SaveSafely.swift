//
//  NSManagedObjectContext+SaveSafely.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 19/09/2025.
//

import CoreData
import os.log
import SwiftUI

// MARK: --- NSManagedObjectContext Safe Save
extension NSManagedObjectContext {
    
    /// Save context safely, showing alert on failure
    func saveSafely(showingAlert: Binding<Bool>, alertMessage: Binding<String>) {
        do {
            if hasChanges {
                try save()
            }
        } catch {
            // 1. Log the error for developers
            os_log("Core Data save failed: %{public}@", log: .default, type: .error, error.localizedDescription)
            
            // 2. Roll back so context isn’t left in a bad state
            rollback()
            
            // 3. Show user-friendly alert
            alertMessage.wrappedValue = "We couldn’t save your changes. Please try again."
            showingAlert.wrappedValue = true
        }
    }
}
