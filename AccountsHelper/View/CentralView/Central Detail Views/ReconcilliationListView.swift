//
//  ReconcilliationListView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 26/09/2025.
//

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
    @State private var reconciliationToDelete: NSManagedObjectID? = nil
//    @State private var selectedReconciliationID: NSManagedObjectID? = nil
    @State private var showingDeleteConfirmation = false
    @State private var showingNewReconciliation = false
    @State private var showDetail = false
    
    // MARK: --- Fetch Request
    @FetchRequest(
        entity: Reconciliation.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Reconciliation.statementDate, ascending: false)]
    ) var reconciliations: FetchedResults<Reconciliation>
    
    // MARK: --- Body
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
                        
//                        Table(rows, selection: Binding(get: {
//                            selectedReconciliationID.map { Set([$0]) } ?? Set()
//                        }, set: { newSelection in
//                            selectedReconciliationID = newSelection.first
//                        })) {
//                        Table(rows, selection: Binding(get: {
//                            appState.selectedReconciliationID.map { Set([$0]) } ?? Set()
//                        }, set: { newSelection in
//                            appState.selectedReconciliationID = newSelection.first
//                        })) {
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
                                    .foregroundColor(hasInvalidTransactions(row) ? .red : .primary)
                                    .contentShape(Rectangle())
                                    .contextMenu { rowContextMenu(row) }
                            }
                            TableColumn("Ending Balance") { row in
                                Text("\(row.rec.endingBalance.formatted(.number.precision(.fractionLength(2)))) \(row.rec.currency.description)")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(hasInvalidTransactions(row) ? .red : .primary)
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
        .onAppear { refreshRows() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
}

// MARK: --- CONTEXT MENU HELPERS
extension ReconcilliationListView {
    
    func addBalancingTransaction(for row: ReconciliationRow, in context: NSManagedObjectContext) {
        do {
            // Step 1: Compute gap in GBP
            var gap = row.rec.reconciliationGap(in: context)
            print("Initial gap (GBP):", gap)

            // Step 2: Clamp NaN or infinite values to zero
            if !gap.isFinite {
                print("Gap is not finite, setting to 0")
                gap = 0
            }

            // Step 3: Clamp tiny differences (< 1 penny) to zero
            if abs(gap) < 0.01 {
                print("Gap < 0.01, ignoring")
                gap = 0
            }

            // Step 4: Only proceed if gap is non-zero
            guard gap != 0 else {
                print("Gap is zero, no balancing transaction needed")
                return
            }

            // Step 5: Create new balancing transaction
            let newTx = Transaction(context: context)
            newTx.payer = .ACHelper
            newTx.paymentMethod = row.rec.paymentMethod
            newTx.payee = "Balancing Transaction"
            newTx.explanation = "Automatically added to force balance"
            newTx.currency = row.rec.currency
            newTx.transactionDate = row.rec.statementDate ?? Date()
            newTx.timestamp = Date()
            newTx.category = .ToBalance

            // Step 6: Set txAmount and debitCredit based on gap
            newTx.txAmount = -gap
            newTx.debitCredit = .DR // Could be .CR does not matter
            
            // Step 6: Set txAmount and debitCredit based on gap
//            if gap > 0 {
//                // Account too low → add debit to increase balance
//                newTx.txAmount = gap
//                newTx.debitCredit = .DR
//            } else {
//                // Account too high → add credit to decrease balance
//                newTx.txAmount = abs(gap)   // always positive
//                newTx.debitCredit = .CR
//            }

            // Step 7: Log transaction for verification
            print("""
                Adding balancing transaction:
                txAmount: \(newTx.txAmount)
                debitCredit: \(newTx.debitCredit)
                currency: \(newTx.currency)
                gap (GBP): \(gap)
                """)
            
            // Step 8: Save
            try context.save()
            print("Balancing transaction saved successfully")
            refreshRows()
            
        } catch {
            print("Failed to add balancing transaction: \(error)")
        }
    }

    
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
            
//            do {
//                // Step 1: Compute gap safely
//                var gap = row.rec.reconciliationGap(in: context)
//                // Step 2: Clamp NaN or infinite values to zero
//                if !gap.isFinite {
//                    gap = 0
//                }
//                // Step 3: Clamp tiny differences to avoid floating-point rounding issues
//                if abs(gap) < 0.01 {
//                    gap = 0
//                }
//                
//                // Step 4: Only proceed if gap is non-zero
//                guard gap != 0 else { return }
//
//                let newTx = Transaction(context: context)
//                newTx.payer = .ACHelper
//                newTx.paymentMethod = row.rec.paymentMethod
//                newTx.payee = "Balancing Transaction"
//                newTx.explanation = "Automatically added to force balance"
//                newTx.currency = row.rec.currency
//                newTx.transactionDate = row.rec.statementDate ?? Date()
//                newTx.timestamp = Date()
//                newTx.category = .ToBalance
//           
//                // Set txAmount and debitCredit correctly
//                if gap > 0 {
//                    // Account is too low → need a debit to increase balance
//                    newTx.txAmount = gap
//                    newTx.debitCredit = .DR
//                } else {
//                    // Account is too high → need a credit to reduce balance
//                    newTx.txAmount = -gap
//                    newTx.debitCredit = .CR
//                }
//                
////                // Normalize and set txAmount
////                newTx.txAmount = abs(gap)
////                
////                // Set debit/credit from sign of gap
////                if gap > 0 {
////                    newTx.debitCredit = .DR   // account has *too little*, so add (debit)
////                } else {
////                    newTx.debitCredit = .CR    // account has *too much*, so subtract (credit))
////                }
//
//                try context.save()
//                refreshRows()
//
//            } catch {
//                print("Failed to add balancing transaction: \(error)")
//            }
        } label: {
            Label("Add Balancing Tx", systemImage: "plus.circle.fill")
        }
        .disabled( row.rec.reconciliationGap(in: context) == 0 )
        
        Divider()
        
        Button(role: .destructive) {
            reconciliationToDelete = row.id
            showingDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}
