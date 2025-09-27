//
//  ReconcileListView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 26/09/2025.
//

import Foundation
import SwiftUI
import CoreData


// MARK: - Row Helper
struct ReconciliationRow {
    let rec: Reconciliation
    let gap: Decimal
}

// MARK: - Reconcile List View
struct ReconcileListView: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.undoManager) private var undoManager
    
    @State private var showingDeleteConfirmation = false
    @State private var reconciliationToDelete: NSManagedObjectID? = nil
    
    @FetchRequest(
        entity: Reconciliation.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Reconciliation.statementDate, ascending: false)]
    ) var reconciliations: FetchedResults<Reconciliation>
    
    @State private var showingNewReconciliation = false
    
    private func deleteReconciliation(_ objectID: NSManagedObjectID) {
        context.perform {
            do {
                guard let rec = try context.existingObject(with: objectID) as? Reconciliation else { return }
                
                // Save data for undo
                let keys = Array(rec.entity.attributesByName.keys)
                let savedData = rec.dictionaryWithValues(forKeys: keys)
                
                // Delete object
                context.delete(rec)
                try context.save()
                
                // Register undo
                undoManager?.registerUndo(withTarget: context) { ctx in
                    let restored = Reconciliation(context: ctx)
                    for (key, value) in savedData {
                        restored.setValue(value, forKey: key)
                    }
                    try? ctx.save()
                }
                undoManager?.setActionName("Delete Reconciliation")
                
            } catch {
                print("Failed to delete reconciliation: \(error)")
                context.rollback()
            }
        }
    }
    
    
    
    // Group by accounting period and precompute gap
    private var groupedReconciliationRows: [(period: AccountingPeriod, rows: [ReconciliationRow])] {
        let dict = Dictionary(grouping: reconciliations) { $0.accountingPeriod }
        return dict.map { (period: $0.key, rows: $0.value.map { rec in
            let gap = (try? rec.reconciliationGap(in: context)) ?? 0
            return ReconciliationRow(rec: rec, gap: gap)
        }) }
        .sorted { lhs, rhs in
            lhs.period.year > rhs.period.year ||
            (lhs.period.year == rhs.period.year && lhs.period.month > rhs.period.month)
        }
    }
    
    var body: some View {
        NavigationStack {
            if reconciliations.isEmpty {
                VStack(spacing: 10) {
                    Text("No reconciliations yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Button("Create First Reconciliation") {
                        showingNewReconciliation = true
                    }
                    .keyboardShortcut("N", modifiers: [.command])
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedReconciliationRows, id: \.period) { period, rows in
                        Section(header: Text(period.displayStringWithOpening).font(.headline)) {
                            //                        Section(header: Text(period.displayString).font(.headline)) {
                            ForEach(rows, id: \.rec) { row in
                                NavigationLink(destination: ReconcileDetailView(reconciliation: row.rec)) {
                                    HStack {
                                        Text(row.rec.paymentMethod.description).bold()
                                        Spacer()
                                        Text("\(row.rec.endingBalance.formatted(.number.precision(.fractionLength(2)))) \(row.rec.currency.description)")
                                        if let date = row.rec.statementDate {
                                            Text(date, style: .date)
                                                .foregroundColor(.gray)
                                        }
                                        if row.gap != 0 {
                                            Text("Gap: \(row.gap.formatted(.number.precision(.fractionLength(2))))")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        reconciliationToDelete = row.rec.objectID
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        //        .navigationTitle("Reconciliations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New") {
                    showingNewReconciliation = true
                }
                .keyboardShortcut("N", modifiers: [.command])
            }
        }
        .sheet(isPresented: $showingNewReconciliation) {
            NavigationStack {
                NewReconciliationView()
                    .environment(\.managedObjectContext, context)
            }
            .frame(minWidth: 400, minHeight: 300) // ✅ larger, resizable sheet
        }
        
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let objectID = reconciliationToDelete {
                    deleteReconciliation(objectID)
                    reconciliationToDelete = nil
                }
            }
        } message: {
            Text("This action can be undone using Undo.")
        }
    }
}

