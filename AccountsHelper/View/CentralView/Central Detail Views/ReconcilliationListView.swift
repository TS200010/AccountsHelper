//
//  ReconcilliationListView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 26/09/2025.
//

import SwiftUI
import CoreData

// MARK: - Row Helper
struct ReconciliationRow: Identifiable, Hashable {
    let rec: Reconciliation
    let gap: Decimal
    var id: NSManagedObjectID { rec.objectID }
}

// MARK: - Reconcile List View
struct ReconcilliationListView: View {

    @Environment(\.managedObjectContext) var context
    @Environment(\.undoManager) private var undoManager
    @Environment(AppState.self) var appState
    
    @State private var showingDeleteConfirmation = false
    @State private var reconciliationToDelete: NSManagedObjectID? = nil
    @State private var showingNewReconciliation = false
    @State private var reconciliationRows: [ReconciliationRow] = []

    @State private var selectedReconciliationID: NSManagedObjectID? = nil
    @State private var showDetail = false

    @FetchRequest(
        entity: Reconciliation.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Reconciliation.statementDate, ascending: false)]
    ) var reconciliations: FetchedResults<Reconciliation>
    
//    private func addBalancingTransaction(for tx: Transaction) {
//        let newTx = Transaction(context: context)
//        newTx.payee = "Balancing Transaction"
//        newTx.explanation = "Automatically added to balance"
//        newTx.currency = tx.currency
//        newTx.txAmount = -gap  // This will make the gap zero
//        newTx.transactionDate = Date()
//        newTx.category = .ToBalance // your custom transaction type
//
//        do {
//            try context.save()
////            loadTransactions() // reload to refresh list and gap
//        } catch {
//            print("Failed to save balancing transaction: \(error)")
//        }
//    }

    

    // MARK: - Delete Function
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
                refreshRows()

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

    // MARK: - Grouped Rows
//    private var groupedReconciliationRows: [(period: AccountingPeriod, rows: [ReconciliationRow])] {
//        let dict = Dictionary(grouping: reconciliations) { $0.accountingPeriod }
//        return dict.map { (period: $0.key, rows: $0.value.map { rec in
//            let gap = (try? rec.reconciliationGap(in: context)) ?? 0
//            return ReconciliationRow(rec: rec, gap: gap)
//        }) }
//        .sorted { lhs, rhs in
//            lhs.period.year > rhs.period.year ||
//            (lhs.period.year == rhs.period.year && lhs.period.month > rhs.period.month)
//        }
//    }
    
    private var groupedReconciliationRows: [(period: AccountingPeriod, rows: [ReconciliationRow])] {
        let dict = Dictionary(grouping: reconciliationRows) { $0.rec.accountingPeriod }
        return dict.map { (period: $0.key, rows: $0.value) }
            .sorted { lhs, rhs in
                lhs.period.year > rhs.period.year ||
                (lhs.period.year == rhs.period.year && lhs.period.month > rhs.period.month)
            }
    }

    private func refreshRows() {
        do {
            let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Reconciliation.statementDate, ascending: false)]
            let recs = try context.fetch(request)

            reconciliationRows = recs.map { rec in
                let gap = (try? rec.reconciliationGap(in: context)) ?? Decimal(0)
                return ReconciliationRow(rec: rec, gap: gap)
            }

        } catch {
            print("Failed to refresh rows: \(error)")
        }
    }
    
    // MARK: - Body
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
                VStack(alignment: .leading) {
                    ForEach(groupedReconciliationRows, id: \.period) { period, rows in
                        Text(period.displayStringWithOpening)
                            .font(.headline)
                            .padding(.top, 4)

                        Table(rows, selection: Binding(get: {
                            selectedReconciliationID.map { Set([$0]) } ?? Set()
                        }, set: { newSelection in
                            selectedReconciliationID = newSelection.first
                        })) {
                            TableColumn("Payment Method") { row in
                                Text(row.rec.paymentMethod.description)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .contextMenu { rowContextMenu(row) }
                            }
                            TableColumn("Ending Balance") { row in
                                Text("\(row.rec.endingBalance.formatted(.number.precision(.fractionLength(2)))) \(row.rec.currency.description)")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .contentShape(Rectangle())
                                    .contextMenu { rowContextMenu(row) }
                            }
                            TableColumn("Statement Date") { row in
                                if let date = row.rec.statementDate {
                                    Text(date, style: .date)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                        .contextMenu { rowContextMenu(row) }
                                }
                            }
                            TableColumn("Gap") { row in
                                if row.gap != 0 {
                                    Text("\(row.gap.formatted(.number.precision(.fractionLength(2))))")
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .contentShape(Rectangle())
                                        .contextMenu { rowContextMenu(row) }
                                }
                            }
                        }
                        .tableStyle(.inset)
                        .frame(minHeight: CGFloat(rows.count) * 28)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            refreshRows()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New") {
                    showingNewReconciliation = true
                }
                .keyboardShortcut("N", modifiers: [.command])
            }
        }
//        .sheet(isPresented: $showingNewReconciliation) {
//            NavigationStack {
//                NewReconciliationView()
//                    .environment(\.managedObjectContext, context)
//            }
//            .frame(minWidth: 400, minHeight: 300)
//        }
        .sheet(isPresented: $showingNewReconciliation, onDismiss: {
            refreshRows()
        }) {
            NavigationStack {
                NewReconciliationView()
                    .environment(\.managedObjectContext, context)
            }
            .frame(minWidth: 400, minHeight: 300)
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
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)) { _ in
            refreshRows()
        } // Belt and braces to ensure the view stays updated
    }

    // MARK: - Row Context Menu
    @ViewBuilder
    private func rowContextMenu(_ row: ReconciliationRow) -> some View {
        Button("Transactions") {
            selectedReconciliationID = row.id
            let predicate = NSPredicate(
                format: "paymentMethodCD == %d AND transactionDate >= %@ AND transactionDate <= %@",
                row.rec.paymentMethod.rawValue,
                row.rec.transactionStartDate as NSDate,
                row.rec.transactionEndDate as NSDate
            )
            appState.pushCentralView(.browseTransactions(predicate))
//            showDetail = true
        }
        
        Button {
            let predicate = NSPredicate(
                format: "paymentMethodCD == %d AND transactionDate >= %@ AND transactionDate <= %@",
                row.rec.paymentMethod.rawValue,
                row.rec.transactionStartDate as NSDate,
                row.rec.transactionEndDate as NSDate
            )
            appState.pushCentralView(.transactionSummary( predicate ))
 //           appState.pushCentralView( .transactionSummary( ) )
        } label: {
            Label("Summary", systemImage: "doc.text.magnifyingglass")
        }
        
        // Calculate gap on demand
        Button("Add Balancing Tx") {
            do {
                let gap = try row.rec.reconciliationGap(in: context)
                guard gap != 0 else { return }

                let newTx = Transaction(context: context)
                newTx.paymentMethod = row.rec.paymentMethod
                newTx.payee = "Balancing Transaction"
                newTx.explanation = "Automatically added to force balance"
                newTx.currency = row.rec.currency
                newTx.txAmount = -gap
                newTx.transactionDate = row.rec.statementDate ?? Date()
                newTx.timestamp = Date()
                newTx.category = .ToBalance

                try context.save()
                refreshRows()
                
//                // Force recalculation / refresh
//                objectWillChange.send() // triggers SwiftUI update
            } catch {
                print("Failed to add balancing transaction: \(error)")
            }
        }
        .disabled((try? row.rec.reconciliationGap(in: context)) == 0)
        
        Divider()
        
        Button(role: .destructive) {
            reconciliationToDelete = row.id
            showingDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}
