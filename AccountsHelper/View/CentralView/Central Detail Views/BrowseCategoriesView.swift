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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryMapping.categoryRawValue, ascending: true)]
    ) private var mappings: FetchedResults<CategoryMapping>

    @State private var selectedMappingIDs = Set<NSManagedObjectID>()
    
    
    private func manualRescanUnknown() {
        let matcher = CategoryMatcher(context: viewContext)
        // This will reapply mappings to unknown transactions (runs on the context queue)
        matcher.reapplyMappingsToUnknownTransactions()
    }

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
        }
        .onAppear {
            for m in mappings {
                print("Mapping \(m.inputString ?? "") -> usageCount: \(m.usageCount)")
            }
        }
    }

    // MARK: - Table
    private var categoriesTable: some View {
        Table(mappingRows, selection: $selectedMappingIDs) {
            TableColumn("Category") { mapping in
                Text(mapping.category.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            TableColumn("Input String") { mapping in
                Text(mapping.inputString ?? "")
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

