//
//  BrowseAMEXTransactionsView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 21/09/2025.
//

/*
import Foundation
import SwiftUI
import CoreData

// MARK: - AMEXTransactionRow Wrapper
fileprivate struct AMEXTransactionRow: Identifiable, Hashable {
    
    let transaction: AMEXTransaction
    var id: NSManagedObjectID { transaction.objectID }

    var category: String { transaction.category ?? "" }
    var transactionDate: Date { transaction.transactionDate ?? .distantPast }
    var payee: String { transaction.appearsOnStatementAs ?? "" }
    var explanation: String { transaction.extendedDetails ?? "" }
    var txAmount: Double { transaction.amount }
    var exchangeRate: Double { transaction.exchangeRate }
    var txAmountGBP: Double { txAmount / exchangeRate }

    var displayAmount: String {
        let formattedAmount: String
        let formattedAmountGBP = String(format: "%.2f", txAmountGBP)
        formattedAmount = String(format: "%.2f", txAmount)
        return "\(formattedAmount) (\(formattedAmountGBP) GBP)"
    }

    var displayFx: String { String(format: "%.2f", exchangeRate) }

    static func == (lhs: AMEXTransactionRow, rhs: AMEXTransactionRow) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - SortColumn
enum AMEXSortColumn: CaseIterable, Identifiable {
    case category, transactionDate, txAmount, exchangeRate, payee, explanation
    var id: Self { self }
    var title: String {
        switch self {
        case .category: return "Category"
        case .transactionDate: return "Date"
        case .txAmount: return "Amount"
        case .exchangeRate: return "Fx"
        case .payee: return "Payee"
        case .explanation: return "Explanation"
        }
    }
    var systemImage: String {
        switch self {
        case .category: return "folder"
        case .transactionDate: return "calendar"
        case .txAmount: return "sum"
        case .exchangeRate: return "chart.line.uptrend.xyaxis"
        case .payee: return "person"
        case .explanation: return "text.alignleft"
        }
    }
    fileprivate func stringKey(for row: AMEXTransactionRow) -> String? {
        switch self {
        case .category: return row.category
        case .payee: return row.payee
        case .explanation: return row.explanation
        default: return nil
        }
    }
    fileprivate func doubleKey(for row: AMEXTransactionRow) -> Double? {
        switch self {
        case .txAmount: return row.txAmount
        case .exchangeRate: return row.exchangeRate
        default: return nil
        }
    }
    fileprivate func dateKey(for row: AMEXTransactionRow) -> Date? {
        switch self {
        case .transactionDate: return row.transactionDate
        default: return nil
        }
    }
}

// MARK: - BrowseAMEXTransactionsView
struct BrowseAMEXTransactionsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.undoManager) private var undoManager
    @Environment(AppState.self) var appState
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AMEXTransaction.transactionDate, ascending: true)]
    ) private var transactions: FetchedResults<AMEXTransaction>

    @State private var selectedTransactionIDs = Set<NSManagedObjectID>()
    @State private var selectedTransaction: AMEXTransaction?
//    @State private var showingEditTransactionSheet = false
//    @State private var showingShowTransactionSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var transactionsToDelete: Set<NSManagedObjectID> = []
    
    @State private var sortColumn: AMEXSortColumn = .transactionDate
    @State private var ascending: Bool = true

    private var transactionRows: [AMEXTransactionRow] {
        let rows = transactions.map { AMEXTransactionRow(transaction: $0) }
        return rows.sorted { lhs, rhs in
            if let l = sortColumn.stringKey(for: lhs), let r = sortColumn.stringKey(for: rhs) {
                let cmp = l.localizedCompare(r)
                return ascending ? cmp == .orderedAscending : cmp == .orderedDescending
            }
            if let l = sortColumn.doubleKey(for: lhs), let r = sortColumn.doubleKey(for: rhs) {
                return ascending ? l < r : l > r
            }
            if let l = sortColumn.dateKey(for: lhs), let r = sortColumn.dateKey(for: rhs) {
                return ascending ? l < r : l > r
            }
            return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            transactionsTable
            statusBar
        }
        .toolbar { toolbarItems }
//        .sheet(isPresented: $showingShowTransactionSheet) {
//            if let transaction = selectedTransaction {
//                // TODO: Add this
//                InspectTransaction(transaction: transaction)
//            }
//        }
//        .sheet(isPresented: $showingEditTransactionSheet) {
            // TODO: Add this
//            EditTransactionSheet(transaction: selectedTransaction)
//        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Selected", role: .destructive) {
                deleteTransactions(with: transactionsToDelete)
            }
        } message: {
            Text("This action cannot be undone (unless you press Undo).")
        }
    }

    private var transactionsTable: some View {
        Table(transactionRows, selection: $selectedTransactionIDs) {
            TableColumn("Date") { row in
                tableCell(row.transactionDate, formatter: dateOnlyFormatter, for: row)
            }
            TableColumn("Amount") { row in
                tableCell(row.displayAmount, for: row)
            }
            TableColumn("Category") { row in
                tableCell(row.category, for: row)
            }
            TableColumn("Fx") { row in
                tableCell(row.displayFx, for: row)
            }
            TableColumn("Payee") { row in
                tableCell(row.payee, for: row)
            }
            TableColumn("Explanation") { row in
                tableCell(row.explanation, for: row)
                    .foregroundColor(.secondary)
            }
        }
        .font(.system(.body, design: .monospaced))
        .frame(minHeight: 300)
        .tableStyle(.inset)
        .contextMenu { sortContextMenu() }
        .onChange(of: selectedTransactionIDs) { newSelection in
            if let firstID = newSelection.first,
               let tx = transactions.first(where: { $0.objectID == firstID }) {
                selectedTransaction = tx
                appState.selectedTransactionID = firstID
                appState.selectedInspectorView = .viewTransaction
            } else {
                selectedTransaction = nil
                appState.selectedTransactionID = nil
            }
        }
    }

    @ViewBuilder
    private func sortContextMenu() -> some View {
        ForEach(AMEXSortColumn.allCases) { column in
            Button {
                updateSortColumn(column)
            } label: {
                Label("Sort by \(column.title)", systemImage: column.systemImage)
            }
        }
    }

    private func updateSortColumn(_ column: AMEXSortColumn) {
        if sortColumn == column {
            ascending.toggle()
        } else {
            sortColumn = column
            ascending = true
        }
        selectedTransactionIDs.removeAll()
    }

    private var statusBar: some View {
        HStack {
            Spacer()
            Text(selectedTransactionIDs.isEmpty
                 ? "Total Transactions: \(transactions.count)"
                 : "Selected: \(selectedTransactionIDs.count)")
        }
        .padding(8)
        .background(Color.platformWindowBackgroundColor)
    }

    private var toolbarItems: some ToolbarContent {
        Group {
//            ToolbarItem {
//                Button(action: { showingEditTransactionSheet.toggle() }) {
//                    Label("Add Item", systemImage: "plus")
//                }
//            }
            ToolbarItem {
                Button(role: .destructive) {
                    transactionsToDelete = selectedTransactionIDs
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
                .disabled(selectedTransactionIDs.isEmpty)
            }
            ToolbarItem {
                Button {
                    undoManager?.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!(undoManager?.canUndo ?? false))
            }
            ToolbarItem {
                Button {
                    undoManager?.redo()
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!(undoManager?.canRedo ?? false))
            }
        }
    }

    @ViewBuilder
    private func tableCell(_ content: String, for row: AMEXTransactionRow) -> some View {
        HStack {
            Text(content)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { rowContextMenu(for: row) }
    }

    @ViewBuilder
    private func tableCell(_ date: Date, formatter: DateFormatter, for row: AMEXTransactionRow) -> some View {
        HStack {
            Text(date, formatter: formatter)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { rowContextMenu(for: row) }
    }

    @ViewBuilder
    private func rowContextMenu(for row: AMEXTransactionRow) -> some View {
        if selectedTransactionIDs.contains(row.id) {
            if selectedTransactionIDs.count == 1 {
//                Button("View Transaction") {
//                    appState.selectedTransactionID = row.id
//                    appState.selectedInspectorView = .viewTransaction
//                    selectedTransaction = row.transaction
//                    showingShowTransactionSheet = true
//                }
                Button("Edit Transaction") {
                    appState.selectedTransactionID = row.id
                    selectedTransaction = row.transaction
//                    showingEditTransactionSheet = true
                }
            }
            Button(role: .destructive) {
                transactionsToDelete = selectedTransactionIDs
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Transaction(s)", systemImage: "trash")
            }
        }
    }

    private func deleteTransactions(with ids: Set<NSManagedObjectID>) {
        viewContext.perform {
            let fetchRequest: NSFetchRequest<AMEXTransaction> = AMEXTransaction.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "self IN %@", ids)
            do {
                let toDelete = try viewContext.fetch(fetchRequest)
                toDelete.forEach { viewContext.delete($0) }
                try viewContext.save()
                selectedTransactionIDs.removeAll()
                undoManager?.setActionName("Delete AMEX Transactions")
            } catch {
                print("Failed to delete AMEX transactions: \(error.localizedDescription)")
                viewContext.rollback()
            }
        }
    }
}
*/
