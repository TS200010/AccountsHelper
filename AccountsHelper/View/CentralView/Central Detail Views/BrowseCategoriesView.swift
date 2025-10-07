//
//  BrowseCategoriesView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 24/09/2025.
//

import Foundation
import SwiftUI
import CoreData

struct BrowseCategoriesView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.undoManager) private var undoManager
    @Environment(AppState.self) var appState

    @State private var showingDeleteConfirmation = false
    @State private var mappingsToDelete: Set<NSManagedObjectID> = []
    @State private var selectedMappingIDs = Set<NSManagedObjectID>()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryMapping.categoryRawValue, ascending: true)]
    ) private var mappings: FetchedResults<CategoryMapping>

    
    private func manualRescanUnknown() {
        let matcher = CategoryMatcher(context: viewContext)
        // This will reapply mappings to unknown transactions (runs on the context queue)
        matcher.reapplyMappingsToUnknownTransactions()
    }
    
    private func deleteMappings(with ids: Set<NSManagedObjectID>) {
        viewContext.perform {
            let fetchRequest: NSFetchRequest<CategoryMapping> = CategoryMapping.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "self IN %@", ids)
            
            do {
                let mappingsToDelete = try viewContext.fetch(fetchRequest)
                
                // Save their data for undo
                let deletedObjectsData: [[String: Any?]] = mappingsToDelete.map { mapping in
                    let keys = Array(mapping.entity.attributesByName.keys)
                    return mapping.dictionaryWithValues(forKeys: keys)
                }
                
                // Delete
                mappingsToDelete.forEach { viewContext.delete($0) }
                try viewContext.save()
                
                selectedMappingIDs.removeAll()
                
                // Register Undo
                undoManager?.registerUndo(withTarget: viewContext) { context in
                    for data in deletedObjectsData {
                        let restored = CategoryMapping(context: context)
                        for (key, value) in data {
                            restored.setValue(value, forKey: key)
                        }
                    }
                    try? context.save()
                    DispatchQueue.main.async {
                        appState.refreshInspector() // AFTER the save
                    }
                }
                undoManager?.setActionName("Delete Category Mappings")
                
            } catch {
                print("Failed to delete category mappings: \(error.localizedDescription)")
                viewContext.rollback()
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for row: CategoryMappingRow) -> some View {
        if selectedMappingIDs.contains(row.id) {
            Button(role: .destructive) {
                mappingsToDelete = selectedMappingIDs
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Mapping(s)", systemImage: "trash")
            }
        }
    }

    // MARK: --- Body
    var body: some View {
        VStack(spacing: 0) {
            categoriesTable
            statusBar
        }
        .frame(minWidth: 400, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { manualRescanUnknown() }) {
                    Label("Rescan unknown transactions", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            ToolbarItem {
                Button(role: .destructive) {
                    mappingsToDelete = selectedMappingIDs
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
                .disabled(selectedMappingIDs.isEmpty)
            }
        }
        .onAppear {
            for m in mappings {
                print("Mapping \(m.inputString ?? "") -> usageCount: \(m.usageCount)")
            }
        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Selected", role: .destructive) {
                deleteMappings(with: mappingsToDelete)
            }
        } message: {
            Text("This action cannot be undone (unless you press Undo).")
        }
    }

    // MARK: - Table
    private var categoriesTable: some View {
        Table(mappingRows, selection: $selectedMappingIDs) {
            TableColumn("Category") { mapping in
                Text(mapping.category.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contextMenu { contextMenu(for: mapping ) }
            }
            TableColumn("Input String") { mapping in
                Text(mapping.inputString)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            TableColumn("Usage Count") { mapping in
                Text("\(mapping.usageCount)")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
//        Table(mappingRows, selection: $selectedMappingIDs) {
//            TableColumn("Category") { row in
//                Text(row.category.description)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            TableColumn("Input String") { row in
//                Text(row.inputString)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            TableColumn("Usage Count") { row in
//                Text("\(row.usageCount)")
//                    .frame(maxWidth: .infinity, alignment: .trailing)
//            }
//        }
        .font(.system(.body, design: .monospaced))
        .frame(minHeight: 300)
        .tableStyle(.inset)
    }

    // MARK: - Status Bar
    private var statusBar: some View {
        HStack {
            Spacer()
            Text(selectedMappingIDs.isEmpty
                 ? "Total Mappings: \(mappings.count)"
                 : "Selected: \(selectedMappingIDs.count)")
        }
        .padding(8)
        .background(Color.platformWindowBackgroundColor)
    }

    // MARK: - Derived Rows
    private var mappingRows: [CategoryMappingRow] {
        mappings.map { CategoryMappingRow(mapping: $0) }
    }
}

// MARK: - Row Struct
struct CategoryMappingRow: Identifiable, Hashable {
    let mapping: CategoryMapping
    var id: NSManagedObjectID { mapping.objectID }
    var category: Category { mapping.category }
    var inputString: String { mapping.inputString ?? "" }
    var usageCount: Int { Int(mapping.usageCount) }
}

