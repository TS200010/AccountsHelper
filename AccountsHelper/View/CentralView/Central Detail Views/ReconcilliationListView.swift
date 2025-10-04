//
//  ReconcilliationListView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 26/09/2025.
//

/*
 
 To Close a reconciliation we need to
 (1) Ensure we canCloseAccountingPeriod()
 */
import SwiftUI
import CoreData

// MARK: --- Row Helper
struct ReconciliationRow: Identifiable, Hashable {
    let rec: Reconciliation
    let gap: Decimal
    var id: NSManagedObjectID { rec.objectID }
}

// MARK: --- Reconcilliation List View
struct ReconcilliationListView: View {
    
    // MARK: --- Environment
    @Environment(\.managedObjectContext) var context
    @Environment(\.undoManager) private var undoManager
    @Environment(AppState.self) var appState
    
    // MARK: --- Local State
    @State private var reconciliationRows: [ReconciliationRow] = []
    @State private var selectedReconciliation: NSManagedObjectID? = nil
    @State private var showingDeleteConfirmation = false
    @State private var showingNewReconciliation = false
    @State private var showingCloseAccountingPeriod = false
    @State private var showDetail = false
    
    // MARK: --- Fetch Request
    @FetchRequest(
        entity: Reconciliation.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Reconciliation.statementDate, ascending: false)]
    ) var reconciliations: FetchedResults<Reconciliation>
    
    // MARK: --- Body
    var body: some View {

        ReconciliationListViewContent
        .onAppear { refreshRows() }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button("New") { showingNewReconciliation = true }
                    .keyboardShortcut("N", modifiers: [.command])
            }
        }
        .sheet(isPresented: $showingNewReconciliation, onDismiss: { refreshRows() }) {
            NavigationStack {
                NewReconciliationView()
                    .environment(\.managedObjectContext, context)
            }
            .frame(minWidth: 400, minHeight: 300)
        }
        .confirmationDialog(
            "Are you sure you want to delete this Reconciliation?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let objectID = selectedReconciliation {
                    deleteReconciliation(objectID)
                    selectedReconciliation = nil
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .confirmationDialog(
            "Are you sure you want to close this Reconciliation?",
            isPresented: $showingCloseAccountingPeriod,
            titleVisibility: .visible
        ) {
            Button("Close", role: .destructive) {
                if let objectID = selectedReconciliation {
                    closeReconciliation(objectID)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)) { _ in
            refreshRows()
        } // Belt and braces to ensure the view stays updated
    }
}

// MARK: --- CONTENT VIEW
extension ReconcilliationListView {
    
    private var ReconciliationListViewContent: some View {
        
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
                            appState.selectedReconciliationID.map { Set([$0]) } ?? Set()
                        }, set: { newSelection in
                            if let selectedID = newSelection.first {
                                appState.selectedReconciliationID = selectedID
                                appState.replaceInspectorView( with: .viewReconciliation)
                            }
                        })) {
                            TableColumn("Payment Method") { row in
                                    Text(row.rec.paymentMethod.description)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(row.rec.closed ? .blue : (hasInvalidTransactions(row) ? .red : .primary))
                                        .contentShape(Rectangle())
                                        .contextMenu { rowContextMenu(row) }
                                }
                                
                                TableColumn("Ending Balance") { row in
                                    Text("\(row.rec.endingBalance.formatted(.number.precision(.fractionLength(2)))) \(row.rec.currency.description)")
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .foregroundColor(row.rec.closed ? .blue : (hasInvalidTransactions(row) ? .red : .primary))
                                        .contentShape(Rectangle())
                                        .contextMenu { rowContextMenu(row) }
                                }
                                
                                TableColumn("Statement Date") { row in
                                    if let date = row.rec.statementDate {
                                        Text(date, style: .date)
                                            .foregroundColor(row.rec.closed ? .blue : .gray)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                            .contextMenu { rowContextMenu(row) }
                                    }
                                }
                                
                                TableColumn("Gap") { row in
                                    if row.gap != 0 {
                                        Text("\(row.gap.formatted(.number.precision(.fractionLength(2))))")
                                            .foregroundColor(row.rec.closed ? .blue : .red)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                            .contentShape(Rectangle())
                                            .contextMenu { rowContextMenu(row) }
                                    }
                                }
                            
//                            TableColumn("Payment Method") { row in
//                                Text(row.rec.paymentMethod.description)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                    .foregroundColor(hasInvalidTransactions(row) ? .red : .primary)
//                                    .foregroundColor(row.rec.closed ? .blue : .primary)
//                                    .contentShape(Rectangle())
//                                    .contextMenu { rowContextMenu(row) }
//                            }
//                            TableColumn("Ending Balance") { row in
//                                Text("\(row.rec.endingBalance.formatted(.number.precision(.fractionLength(2)))) \(row.rec.currency.description)")
//                                    .frame(maxWidth: .infinity, alignment: .trailing)
//                                    .foregroundColor(hasInvalidTransactions(row) ? .red : .primary)
//                                    .contentShape(Rectangle())
//                                    .contextMenu { rowContextMenu(row) }
//                            }
//                            TableColumn("Statement Date") { row in
//                                if let date = row.rec.statementDate {
//                                    Text(date, style: .date)
//                                        .foregroundColor(.gray)
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                        .contentShape(Rectangle())
//                                        .contextMenu { rowContextMenu(row) }
//                                }
//                            }
//                            TableColumn("Gap") { row in
//                                if row.gap != 0 {
//                                    Text("\(row.gap.formatted(.number.precision(.fractionLength(2))))")
//                                        .foregroundColor(.red)
//                                        .frame(maxWidth: .infinity, alignment: .trailing)
//                                        .contentShape(Rectangle())
//                                        .contextMenu { rowContextMenu(row) }
//                                }
//                            }
                        }
                        .tableStyle(.inset)
                        .frame(minHeight: CGFloat(rows.count) * 28)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}


// MARK: --- FETCH HELPERS
extension ReconcilliationListView {
    
    private func refreshRows() {
        do {
            let request: NSFetchRequest<Reconciliation> = Reconciliation.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Reconciliation.statementDate, ascending: false)]
            let recs = try context.fetch(request)
            
            reconciliationRows = recs.map { rec in
                let gap = rec.reconciliationGap(in: context)
                return ReconciliationRow(rec: rec, gap: gap)
            }
            
        } catch {
            print("Failed to refresh rows: \(error)")
        }
    }
    
    private var groupedReconciliationRows: [(period: AccountingPeriod, rows: [ReconciliationRow])] {
        let dict = Dictionary(grouping: reconciliationRows) { $0.rec.accountingPeriod }
        return dict.map { (period: $0.key, rows: $0.value) }
            .sorted { lhs, rhs in
                lhs.period.year > rhs.period.year ||
                (lhs.period.year == rhs.period.year && lhs.period.month > rhs.period.month)
            }
    }
    
    private func hasInvalidTransactions(_ row: ReconciliationRow) -> Bool {
        !(row.rec.isValid(in: context))
    }
    
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
                appState.refreshInspector()

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
    
    // MARK: --- CloseReconciliation
    private func closeReconciliation(_ objectID: NSManagedObjectID) {
        context.perform {
            do {
                guard let rec = try context.existingObject(with: objectID) as? Reconciliation else { return }

                // Save data for undo
                let keys = Array(rec.entity.attributesByName.keys)
                let savedData = rec.dictionaryWithValues(forKeys: keys)

                // Close Reconciliation
                try rec.close(in: context)
                try context.save()
                DispatchQueue.main.async {
                    refreshRows()
                    appState.refreshInspector()
                }

                // Register undo
                undoManager?.registerUndo(withTarget: context) { ctx in
                    let restored = Reconciliation(context: ctx)
                    for (key, value) in savedData {
                        restored.setValue(value, forKey: key)
                    }
                    try? ctx.save()
                }
                undoManager?.setActionName("Close Reconciliation")
            } catch {
                print("Failed to close reconciliation: \(error)")
                context.rollback()
            }
        }
    }
}

// MARK: --- CONTEXT MENU HELPERS
extension ReconcilliationListView {
    
    // MARK: --- AddBalancingTransaction
    func addBalancingTransaction(for row: ReconciliationRow, in context: NSManagedObjectContext) {
        do {
            var gap = row.rec.reconciliationGap(in: context)
            if !gap.isFinite { gap = 0 } // Clamp NaN or infinite values to zero
            if abs(gap) < 0.01 {  gap = 0 }
            guard gap != 0 else { return }
            
            let newTx = Transaction(context: context)
            newTx.payer = .ACHelper
            newTx.paymentMethod = row.rec.paymentMethod
            newTx.payee = "Balancing Transaction"
            newTx.explanation = "Automatically added to force balance"
            newTx.currency = row.rec.currency
            newTx.transactionDate = row.rec.statementDate ?? Date()
            newTx.timestamp = Date()
            newTx.category = .ToBalance
            
            newTx.txAmount = -gap
            newTx.debitCredit = .DR // Could be .CR does not matter
            
            // Log transaction for verification
            print("""
                Adding balancing transaction:
                txAmount: \(newTx.txAmount)
                debitCredit: \(newTx.debitCredit)
                currency: \(newTx.currency)
                gap (GBP): \(gap)
                """)
            
            try context.save()
            print("Balancing transaction saved successfully")
            refreshRows()
            appState.refreshInspector()
            
        } catch {
            print("Failed to add balancing transaction: \(error)")
        }
    }
}


// MARK: --- VIEW CONTEXT MENU
extension ReconcilliationListView {
    
    // MARK: --- RowContextMenu
    @ViewBuilder
    private func rowContextMenu(_ row: ReconciliationRow) -> some View {
        Button {
            appState.selectedReconciliationID = row.id
            appState.replaceInspectorView( with: .viewReconciliation)
            let predicate = NSPredicate(
                format: "paymentMethodCD == %d AND transactionDate >= %@ AND transactionDate <= %@",
                row.rec.paymentMethod.rawValue,
                row.rec.transactionStartDate as NSDate,
                row.rec.transactionEndDate as NSDate
            )
            appState.pushCentralView(.browseTransactions(predicate))
        } label: {
            Label("Transactions", systemImage: "list.bullet")
        }
        
        Button {
            let predicate = NSPredicate(
                format: "paymentMethodCD == %d AND transactionDate >= %@ AND transactionDate <= %@",
                row.rec.paymentMethod.rawValue,
                row.rec.transactionStartDate as NSDate,
                row.rec.transactionEndDate as NSDate
            )
            appState.pushCentralView(.transactionSummary(predicate))
        } label: {
            Label("Summary", systemImage: "doc.text.magnifyingglass")
        }
        
        Button {
            addBalancingTransaction(for: row, in: context)
        } label: {
            Label("Add Balancing Tx", systemImage: "plus.circle.fill")
        }
        .disabled( row.rec.reconciliationGap(in: context) == 0 )
        
        Button {
            selectedReconciliation = row.id  
            showingCloseAccountingPeriod = true
        } label: {
            Label("Close Period", systemImage: "checkmark.square.fill")
        }
        .disabled(!row.rec.canCloseAccountingPeriod(in: context))
        
        Divider()
        
        Button(role: .destructive) {
            selectedReconciliation = row.id
            showingDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}
