//
//  BrowseTransactionsView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 16/09/2025.
//

import Foundation
import SwiftUI
import CoreData

// MARK: - TransactionRow Wrapper
fileprivate struct TransactionRow: Identifiable, Hashable {
    let transaction: Transaction
    var id: NSManagedObjectID { transaction.objectID }

    var category: String { transaction.category.description }
    var splitCategory: String { transaction.splitCategory.description }
    var currency: String { transaction.currency.description }
    var debitCredit: String { transaction.debitCredit.description }
    var exchangeRate: Double { (transaction.exchangeRate as NSDecimalNumber?)?.doubleValue ?? 0.0 }
    
    var transactionDate: Date { transaction.transactionDate ?? .distantPast }
    var paymentMethod: String { transaction.paymentMethod.description }
    var payee: String { transaction.payee ?? "" }
    var payer: String { transaction.payer.description }
    var explanation: String { transaction.explanation ?? "" }
    var splitAmount1: Double { (transaction.splitAmount as NSDecimalNumber?)?.doubleValue ?? 0.0 }
    var txAmount: Double { (transaction.txAmount as NSDecimalNumber?)?.doubleValue ?? 0.0 }
    var txAmountGBP: Double {
        txAmount / exchangeRate
    }

//    var displayAmountX: String {
//        "\(currency) \(String(format: "%.2f", txAmount)) \(transaction.debitCredit == .DR ? debitCredit : "" )"
//    }
    
    var displayAmount: String {
        let formattedAmount: String
        let formattedAmountGBP: String
        formattedAmountGBP = String(format: "%.2f", txAmountGBP )
        if transaction.currency == .JPY {
            // No decimal places for Japanese Yen
            formattedAmount = String(format: "%.0f", txAmount)
        } else {
            // Two decimal places for other currencies
            formattedAmount = String(format: "%.2f", txAmount)
        }
        var resultWIP = "\(currency) \(formattedAmount) \(transaction.debitCredit == .DR ? debitCredit : "")"
        if transaction.currency == .GBP {
            return resultWIP
        } else {
            
            return resultWIP + "in GBP \(formattedAmountGBP)"
        }
    }
    
    var displayFx: String {
        let formattedFx: String
        if transaction.currency == .JPY {
            // No decimal places for Japanese Yen
            formattedFx = String(format: "%.0f", exchangeRate)
        } else {
            // Two decimal places for other currencies
            formattedFx = String(format: "%.2f", exchangeRate)
        }
        return "\(formattedFx)"
    }
    
    static func == (lhs: TransactionRow, rhs: TransactionRow) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - SortColumn
enum SortColumn: CaseIterable, Identifiable {
    case category, splitaCategory, currency, debitCredit, exchangeRate,
         explanation, payee, payer, paymentMethod, splitAmount, transactionDate, txAmount
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .category:        return "Category"
        case .splitaCategory:  return "SplitCategory"
        case .currency:        return "Currency"
        case .debitCredit:     return "Debit/Credit"
        case .exchangeRate:    return "Fx"
        case .explanation:     return "Explanation"
        case .payee:           return "Payee"
        case .payer:           return "Payer"
        case .paymentMethod:   return "Payment Method"
        case .splitAmount:    return "SplitAmount"
        case .transactionDate: return "Date"
        case .txAmount:        return "Amount"
        }
    }
    
    var systemImage: String {
        switch self {
        case .transactionDate: return "calendar"
        case .category:        return "folder"
        case .splitaCategory:       return "folder.fill"
        case .currency:        return "dollarsign.circle"
        case .debitCredit:     return "arrow.left.arrow.right"
        case .exchangeRate:    return "chart.line.uptrend.xyaxis"
        case .paymentMethod:   return "creditcard"
        case .payee:           return "person"
        case .payer:           return "person.crop.circle"
        case .explanation:     return "text.alignleft"
        case .splitAmount:    return "number"
        case .txAmount:        return "sum"
        }
    }
    
    // Extract comparable values
    fileprivate func stringKey(for row: TransactionRow) -> String? {
        switch self {
        case .category:       return row.category
        case .splitaCategory:      return row.splitCategory
        case .currency:       return row.currency
        case .debitCredit:    return row.debitCredit
        case .payee:          return row.payee
        case .payer:          return row.payer
        case .paymentMethod:  return row.paymentMethod
        case .explanation:    return row.explanation
        default:              return nil
        }
    }
    
    fileprivate func doubleKey(for row: TransactionRow) -> Double? {
        switch self {
        case .exchangeRate: return row.exchangeRate
        case .splitAmount: return row.splitAmount1
        case .txAmount:     return row.txAmount
        default:            return nil
        }
    }
    
    fileprivate func dateKey(for row: TransactionRow) -> Date? {
        switch self {
        case .transactionDate: return row.transactionDate
        default: return nil
        }
    }
}

// MARK: - BrowseTransactionsView
struct BrowseTransactionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.undoManager) private var undoManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)]
    ) private var transactions: FetchedResults<Transaction>

    @State private var selectedTransactionIDs = Set<NSManagedObjectID>()
    @State private var transactionToShow: Transaction?
    @State private var showingTransactionSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var transactionsToDelete: Set<NSManagedObjectID> = []
    
    // Sorting state
    @State private var sortColumn: SortColumn = .transactionDate
    @State private var ascending: Bool = true
    
    // MARK: - Derived Rows
    private var transactionRows: [TransactionRow] {
        let rows = transactions.map { TransactionRow(transaction: $0) }
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
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            transactionsTable
            statusBar
        }
        .toolbar { toolbarItems }
        .sheet(item: $transactionToShow) { transaction in
            ShowTransactionView(transaction: transaction)
        }
        .sheet(isPresented: $showingTransactionSheet) {
            EditTransactionView(transaction: transactionToShow)
        }
//        .sheet(item: $transactionToShow) { ShowTransactionView(transaction: $0) }
//        .sheet(isPresented: $showingTransactionSheet) { EditTransactionView() }
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

    // MARK: - Transactions Table
    private var transactionsTable: some View {
        Table(transactionRows, selection: $selectedTransactionIDs) {
//        Table(transactionRows, selection: $selectedTransactionIDs, rowID: \.transaction.objectID) {
            #if os(macOS)
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
//                tableCell(String(format: "%.4f", row.exchangeRate), for: row)
                tableCell(row.displayFx, for: row)
            }
            TableColumn("Payee") { row in
                tableCell(row.payee, for: row)
            }
            TableColumn("Payer") { row in
                tableCell(row.payer, for: row)
            }
            TableColumn("Payment Method") { row in
                tableCell(row.paymentMethod, for: row)
            }
            TableColumn("SplitCategory") { row in
                tableCell(row.splitCategory, for: row)
            }
            TableColumn("SplitAmount") { row in
                tableCell(String(format: "%.2f", row.splitAmount1), for: row)
            }
            TableColumn("Explanation") { row in
                tableCell(row.explanation, for: row)
                    .foregroundColor(.secondary)
            }
            #else
            TableColumn("Date") { row in
                tableCell(row.transactionDate, formatter: dateOnlyFormatter, for: row)
            }
            TableColumn("Amount") { row in
                tableCell(row.displayAmount, for: row)
            }
            #endif

        }
        .font(.system(.body, design: .monospaced))
        .frame(minHeight: 300)
        .tableStyle(.inset)
        .contextMenu { SortContextMenu() }
    }
    
    // MARK: - SortContextMenu
    @ViewBuilder
    private func SortContextMenu() -> some View {
        ForEach(SortColumn.allCases) { column in
            Button {
                updateSortColumn(column)
            } label: {
                Label("Sort by \(column.title)", systemImage: column.systemImage)
            }
        }
    }
    
    // MARK: - UpdateSortColumn
    private func updateSortColumn(_ column: SortColumn) {
        if sortColumn == column {
            ascending.toggle()
        } else {
            sortColumn = column
            ascending = true
        }
        
        // Safe: remove any selection (even if empty, harmless)
        selectedTransactionIDs.removeAll()
    }

    // MARK: - Status Bar
    private var statusBar: some View {
        HStack {
            Spacer()
            Text(selectedTransactionIDs.isEmpty
                 ? "Total Transactions: \(transactions.count)"
                 : "Selected: \(selectedTransactionIDs.count)")
        }
        .padding(8)
        .background( Color.platformWindowBackgroundColor )
    }

    // MARK: - Toolbar
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem {
                Button(action: { showingTransactionSheet.toggle() }) {
                    Label("Add Item", systemImage: "plus")
                }
            }
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
    
    // MARK: - Table Cell Helpers
    @ViewBuilder
    private func tableCell(_ content: String, for row: TransactionRow) -> some View {
        HStack {
            Text(content)
//                .font(.system(.body, design: .monospaced))
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }
    
    @ViewBuilder
    private func tableCell(_ date: Date, formatter: DateFormatter, for row: TransactionRow) -> some View {
        HStack {
            Text(date, formatter: formatter)
//                .font(.system(.body, design: .monospaced))
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }

    // MARK: - Context Menu for Row
    @ViewBuilder
    private func contextMenu(for row: TransactionRow) -> some View {
        if selectedTransactionIDs.contains(row.id) {
            if selectedTransactionIDs.count == 1 {
                Button("View Transaction") {
                    transactionToShow = row.transaction
                }
                Button("Edit Transaction") {
                    transactionToShow = row.transaction
                    showingTransactionSheet = true
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

    // MARK: - Actions
    private func deleteTransactions(with ids: Set<NSManagedObjectID>) {
        viewContext.perform {
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "self IN %@", ids)
            do {
                let transactionsToDelete = try viewContext.fetch(fetchRequest)
                let deletedObjectsData: [[String: Any?]] = transactionsToDelete.map { transaction in
                    let keys = Array(transaction.entity.attributesByName.keys)
                    return transaction.dictionaryWithValues(forKeys: keys)
                }
                transactionsToDelete.forEach { viewContext.delete($0) }
                try viewContext.save()
                selectedTransactionIDs.removeAll()
                undoManager?.registerUndo(withTarget: viewContext) { context in
                    for data in deletedObjectsData {
                        let restored = Transaction(context: context)
                        for (key, value) in data {
                            restored.setValue(value, forKey: key)
                        }
                    }
                    try? context.save()
                }
                undoManager?.setActionName("Delete Transactions")
            } catch {
                print("Failed to delete transactions: \(error.localizedDescription)")
                viewContext.rollback()
            }
        }
    }
}
