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
    // MARK: --- Properties
    let rec: Reconciliation
    let gap: Decimal
    
    // MARK: --- ID
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
    @State private var showingDeleteConfirmation = false
    @State private var showingNewReconciliation = false
    @State private var showingCloseAccountingPeriod = false
    @State private var showingXLSConfirmation = false
    @State private var showDetail = false
    @State private var showingEditReconciliation = false
    
    // MARK: --- Fetch Request
    @FetchRequest(
        entity: Reconciliation.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Reconciliation.statementDate, ascending: false)]
    ) var reconciliations: FetchedResults<Reconciliation>
    
    // MARK: --- Body
    var body: some View {
        // MARK: --- ReconciliationListContent
        reconciliationListContent
            .onAppear { refreshRows() }
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingNewReconciliation, onDismiss: { refreshRows() }) { newReconciliationSheet }
            .sheet(isPresented: $showingEditReconciliation, onDismiss: { refreshRows() }) { editReconciliationSheet }
            .confirmationDialog(
                "Are you sure you want to delete this Reconciliation?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) { deleteConfirmationDialog } message: { deleteConfirmationMessage }
            .confirmationDialog(
                "Are you sure you want to close this Reconciliation?",
                isPresented: $showingCloseAccountingPeriod,
                titleVisibility: .visible
            ) { closeConfirmationDialog }
            .confirmationDialog(
                "Category totals copied to clipboard.",
                isPresented: $showingXLSConfirmation,
                titleVisibility: .visible
            ) { xlsConfirmationDialog }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: context)) { _ in
                refreshRows()
            }
        
    }
}

// MARK: --- TOOLBAR CONTENT
extension ReconcilliationListView {
    // MARK: --- toolbarContent
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button("New") { showingNewReconciliation = true }
                .keyboardShortcut("N", modifiers: [.command])
        }
    }
}

// MARK: --- SHEET VIEWS
extension ReconcilliationListView {
    // MARK: --- newReconciliationSheet
    private var newReconciliationSheet: some View {
        NavigationStack {
            NewReconciliationView()
                .environment(\.managedObjectContext, context)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    // MARK: --- editReconciliationSheet
    private var editReconciliationSheet: some View {
        NavigationStack {
            EditReconcilationView()
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: --- CONFIRMATION DIALOGS
extension ReconcilliationListView {
    // MARK: --- deleteConfirmationDialog
    @ViewBuilder
    private var deleteConfirmationDialog: some View {
        Button("Delete", role: .destructive) {
            if let objectID = appState.selectedReconciliationID {
                deleteReconciliation(objectID)
                appState.selectedReconciliationID = nil
            }
        }
    }
    
    // MARK: --- deleteConfirmationMessage
    private var deleteConfirmationMessage: some View {
        Text("This action cannot be undone.")
    }
    
    // MARK: --- closeConfirmationDialog
    @ViewBuilder
    private var closeConfirmationDialog: some View {
        Button("Close", role: .destructive) {
            if let objectID = appState.selectedReconciliationID {
                closeReconciliation(objectID)
            }
        }
    }
    
    // MARK: --- xlsConfirmationDialog
    @ViewBuilder
    private var xlsConfirmationDialog: some View {
        Button("OK", role: .cancel) { }
    }
}
// MARK: --- CONTENT VIEW
extension ReconcilliationListView {
    
//    private func formattedCurrency(_ amount: Decimal, currency: Currency) -> String {
//        amount.formatted(.currency(code: currency.code).locale)
//    }
    
    // MARK: --- reconciliationListContent
    private var reconciliationListContent: some View {
        NavigationStack {
            if reconciliations.isEmpty {
                emptyStateView
            } else {
                reconciliationTableView
            }
        }
    }
    
    // MARK: --- emptyStateView
    private var emptyStateView: some View {
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
    }
    
    // MARK: --- reconciliationTableView
    private var reconciliationTableView: some View {
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
                        appState.replaceInspectorView(with: .viewReconciliation)
                    }
                })) {
                    TableColumn("Payment Method") { row in
                        Text(row.rec.paymentMethod.description)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(row.rec.closed ? .blue : (hasInvalidTransactions(row) ? .red : .primary))
                            .contentShape(Rectangle())
                            .contextMenu { rowContextMenu(row) }
                    }
                    
                    TableColumn("Opening Balance") { row in
                        Text(row.rec.previousEndingBalance.formattedAsCurrency(row.rec.currency))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(row.rec.closed ? .blue : (hasInvalidTransactions(row) ? .red : .primary))
                            .contentShape(Rectangle())
                            .contextMenu { rowContextMenu(row) }
                    }
                    

                    TableColumn("Net Transactions") { row in
                        Text(row.rec.totalTransactions.formattedAsCurrency(row.rec.currency))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(row.rec.closed ? .blue : (hasInvalidTransactions(row) ? .red : .primary))
                            .contentShape(Rectangle())
                            .contextMenu { rowContextMenu(row) }
                    }
                    
                    TableColumn("Ending Balance") { row in
                        Text(row.rec.endingBalance.formattedAsCurrency(row.rec.currency))
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                            Text(row.gap.formattedAsCurrency(row.rec.currency))
                                .foregroundColor(row.rec.closed ? .blue : .red)
                                .frame(maxWidth: .infinity, alignment: .leading)
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


// MARK: --- FETCH HELPERS
extension ReconcilliationListView {
    // MARK: --- refreshRows
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
    
    // MARK: --- GroupedReconciliationRows
    private var groupedReconciliationRows: [(period: AccountingPeriod, rows: [ReconciliationRow])] {
        let dict = Dictionary(grouping: reconciliationRows) { $0.rec.accountingPeriod }
        return dict.map { (period: $0.key, rows: $0.value) }
            .sorted { lhs, rhs in
                lhs.period.year > rhs.period.year ||
                (lhs.period.year == rhs.period.year && lhs.period.month > rhs.period.month)
            }
    }
    
    // MARK: --- HasInvalidTransactions
    private func hasInvalidTransactions(_ row: ReconciliationRow) -> Bool {
        !(row.rec.isValid(in: context))
    }
    
    // MARK: --- DeleteReconciliation
    private func deleteReconciliation(_ objectID: NSManagedObjectID) {
        context.perform {
            do {
                guard let rec = try context.existingObject(with: objectID) as? Reconciliation else { return }

                let keys = Array(rec.entity.attributesByName.keys)
                let savedData = rec.dictionaryWithValues(forKeys: keys)

                context.delete(rec)
                try context.save()
                refreshRows()
                appState.refreshInspector()

                undoManager?.registerUndo(withTarget: context) {  ctx in
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

                let keys = Array(rec.entity.attributesByName.keys)
                let savedData = rec.dictionaryWithValues(forKeys: keys)

                try rec.close(in: context)
                try context.save()
                DispatchQueue.main.async {
                    refreshRows()
                    appState.refreshInspector()
                }

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
    private func addBalancingTransaction(for row: ReconciliationRow, in context: NSManagedObjectContext) {
        do {
            var gap = row.rec.reconciliationGap(in: context)
            if !gap.isFinite { gap = 0 }
            if abs(gap) < 0.01 { gap = 0 }
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
            newTx.debitCredit = .DR
            
            print("""
                Adding balancing transaction:
                txAmount: \(newTx.txAmount)
                debitCredit: \(newTx.debitCredit)
                currency: \(newTx.currency)
                gap (GBP): \(gap)
                """)
            
            try context.save()
            refreshRows()
            appState.refreshInspector()
        } catch {
            print("Failed to add balancing transaction: \(error)")
        }
    }
    
    // MARK: --- CategoryTotals
    fileprivate func categoryTotals(for row: ReconciliationRow) -> [Category: Decimal] {
        do {
            let predicate = NSPredicate(
                format: "paymentMethodCD == %d AND transactionDate >= %@ AND transactionDate <= %@",
                row.rec.paymentMethod.rawValue,
                row.rec.transactionStartDate as NSDate,
                row.rec.transactionEndDate as NSDate
            )
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            fetchRequest.predicate = predicate
            let transactions = try context.fetch(fetchRequest)

            return transactions.sumByCategoryIncludingSplitsInGBP()

        } catch {
            print("Failed to fetch category totals for reconciliation: \(error)")
            return [:]
        }
    }
    
    // MARK: --- ExportXLSSummary
    private func exportXLSSummary(for row: ReconciliationRow) {
        #if os(macOS)
        let totals = categoryTotals(for: row)

        let text = Category.allCases.map { category in
            let total = totals[category] ?? 0
            return "\(category.description)\t\(total.string2f)"
        }.joined(separator: "\n")

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        showingXLSConfirmation = true
        #endif
    }
}

// MARK: --- VIEW CONTEXT MENU
extension ReconcilliationListView {
    
    // MARK: --- RowContextMenu
    @ViewBuilder
    private func rowContextMenu(_ row: ReconciliationRow) -> some View {
        
        var canAddBalancingTransaction: Bool {
            row.rec.reconciliationGap(in: context) == 0 || row.rec.closed || row.rec.isAnOpeningBalance
        }
        
        var canAddEndingBalance: Bool {
            row.rec.closed
        }
        
        Button {
            appState.selectedReconciliationID = row.id
            appState.replaceInspectorView(with: .viewReconciliation)
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
            appState.pushCentralView(.categoriesSummary(predicate))
        } label: {
            Label("Summary", systemImage: "doc.text.magnifyingglass")
        }
        
        Button { exportXLSSummary(for: row) } label: {
            Label("XLS Summary", systemImage: "doc.on.doc")
        }

        Button { addBalancingTransaction(for: row, in: context) } label: {
            Label("Add Balancing Tx", systemImage: "plus.circle.fill")
        }
        .disabled(canAddBalancingTransaction)
        
        Button {
            appState.selectedReconciliationID = row.id
            showingEditReconciliation = true
        } label: {
            Label("Edit Ending Balance", systemImage: "pencil.circle")
        }
        .disabled(canAddEndingBalance)
        
        Button {
            appState.selectedReconciliationID = row.id
            showingCloseAccountingPeriod = true
        } label: {
            Label("Close Period", systemImage: "checkmark.square.fill")
        }
        .disabled(!row.rec.canCloseAccountingPeriod(in: context) || row.rec.closed)
        
        Button {
            appState.selectedReconciliationID = row.id
            do {
                try row.rec.reopen(in: context)
                refreshRows()
                appState.refreshInspector()
            } catch {
                print("Failed to reopen reconciliation: \(error)")
            }
        } label: {
            Label("Reopen Period", systemImage: "arrow.uturn.left.square.fill")
        }
        .disabled(!row.rec.isClosed || !row.rec.canReopenAccountingPeriod(in: context))
        
        Divider()
        
        Button(role: .destructive) {
            appState.selectedReconciliationID = row.id
            showingDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .disabled(!row.rec.canDelete(in: context))
    }
}
