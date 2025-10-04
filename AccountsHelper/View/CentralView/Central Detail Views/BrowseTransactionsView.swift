//
//  BrowseTransactionsView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 16/09/2025.
//

import Foundation
import SwiftUI
import CoreData

// MARK: --- TransactionRow Wrapper
fileprivate struct TransactionRow: Identifiable, Hashable {
    
    let transaction: Transaction
    var id: NSManagedObjectID { transaction.objectID }

    // MARK: --- Category
    var category: String { transaction.category.description }

    // MARK: --- Currency
    var currency: String { transaction.currency.description }

    // MARK: --- DebitCredit
    var debitCredit: String { transaction.debitCredit.description }

    // MARK: --- DisplayAmount
    var displayAmount: String {
        let rawAmount = NSDecimalNumber(decimal: transaction.txAmount)
        let rawFx = NSDecimalNumber(decimal: transaction.exchangeRate)
        let txAmount: Double = rawAmount.doubleValue
        let exchangeRate: Double = rawFx.doubleValue
        let txAmountGBP: Double = txAmount / (exchangeRate == 0 ? 1 : exchangeRate)
        let formattedAmount: String
        let formattedAmountGBP = String(format: "%.2f", txAmountGBP)
        if transaction.currency == .JPY {
            formattedAmount = String(format: "%.0f", txAmount)
        } else {
            formattedAmount = String(format: "%.2f", txAmount)
        }
        var result = "\(currency) \(formattedAmount) \(transaction.debitCredit == .DR ? debitCredit : "")"
        if transaction.currency == .GBP {
            return result
        } else {
            #if os(macOS)
            return result + "\nGBP \(formattedAmountGBP)"
            #else
            return result + " GBP \(formattedAmountGBP)"
            #endif
        }
    }

    // MARK: --- DisplaySplitAmount
    var displaySplitAmount: String {
        if transaction.splitAmount == Decimal(0) { return "" }
        let rawSplit = NSDecimalNumber(decimal: transaction.splitAmount).doubleValue
        let rawRemainder = NSDecimalNumber(decimal: transaction.splitRemainderAmount).doubleValue
        let formattedSplit = transaction.currency == .JPY ? String(format: "%.0f", rawSplit) : String(format: "%.2f", rawSplit)
        let formattedRemainder = transaction.currency == .JPY ? String(format: "%.0f", rawRemainder) : String(format: "%.2f", rawRemainder)
        let splitPad = String(repeating: " ", count: max(0, 5 - formattedSplit.count))
        let remainderPad = String(repeating: " ", count: max(0, 5 - formattedRemainder.count))
        var result = "\(currency) \(formattedSplit)" + splitPad + " \(splitCategory)"
        result += "\n\(currency) \(formattedRemainder)" + remainderPad + " \(splitRemainderCategory)"
        return result
    }

    // MARK: --- Explanation
    var explanation: String { transaction.explanation ?? "" }

    // MARK: --- iOSRowForDisplay
    var iOSRowForDisplay: String {
        var parts: [String] = []
        if !transactionDate.isEmpty { parts.append(transactionDate) }
        if !displayAmount.isEmpty { parts.append(displayAmount) }
        if !payee.isEmpty && !category.isEmpty { parts.append("\(payee): \(category)") }
        return parts.joined(separator: "\n")
    }

    // MARK: --- PaymentMethod
    var paymentMethod: String { transaction.paymentMethod.description }

    // MARK: --- Payer
    var payer: String { transaction.payer.description }

    // MARK: --- Payee
    var payee: String { transaction.payee ?? "" }

    // MARK: --- SplitCategory
    var splitCategory: String { transaction.splitCategory.description }

    // MARK: --- SplitRemainderAsString
    var splitRemainderAsString: String {
        guard let amount = transaction.splitRemainderAmount as? NSDecimalNumber else { return "" }
        return String(format: "%.2f", amount.doubleValue)
    }

    // MARK: --- SplitRemainderCategory
    var splitRemainderCategory: String { transaction.splitRemainderCategory.description }

    // MARK: --- TransactionDate
    var transactionDate: String { transaction.transactionDateAsString() ?? "" }

    // MARK: --- TxAmount
    var txAmount: String { transaction.txAmountAsString() ?? "" }

    // MARK: --- ExchangeRate
    var exchangeRate: String { transaction.exchangeRateAsString() ?? "" }

    static func == (lhs: TransactionRow, rhs: TransactionRow) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: --- SortColumn
enum SortColumn: CaseIterable, Identifiable {
    case category, splitCategory, currency, debitCredit, exchangeRate,
         explanation, payee, payer, paymentMethod, splitAmount, transactionDate, txAmount

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .transactionDate: return "calendar"
        case .category:        return "folder"
        case .splitCategory:   return "folder.fill"
        case .currency:        return "dollarsign.circle"
        case .debitCredit:     return "arrow.left.arrow.right"
        case .exchangeRate:    return "chart.line.uptrend.xyaxis"
        case .paymentMethod:   return "creditcard"
        case .payee:           return "person"
        case .payer:           return "person.crop.circle"
        case .explanation:     return "text.alignleft"
        case .splitAmount:     return "number"
        case .txAmount:        return "sum"
        }
    }

    var title: String {
        switch self {
        case .category:        return "Category"
        case .splitCategory:   return "SplitCategory"
        case .currency:        return "Currency"
        case .debitCredit:     return "Debit/Credit"
        case .exchangeRate:    return "Fx"
        case .explanation:     return "Explanation"
        case .payee:           return "Payee"
        case .payer:           return "Payer"
        case .paymentMethod:   return "Payment Method"
        case .splitAmount:     return "SplitAmount"
        case .transactionDate: return "Date"
        case .txAmount:        return "Amount"
        }
    }

    fileprivate func stringKey(for row: TransactionRow) -> String? {
        switch self {
        case .category:        return row.category
        case .splitCategory:   return row.splitCategory
        case .currency:        return row.currency
        case .debitCredit:     return row.debitCredit
        case .payee:           return row.payee
        case .payer:           return row.payer
        case .paymentMethod:   return row.paymentMethod
        case .explanation:     return row.explanation
        case .transactionDate: return row.transactionDate
        case .txAmount:        return row.txAmount
        case .exchangeRate:    return row.exchangeRate
        default:               return nil
        }
    }
}

// MARK: --- BrowseTransactionsView
struct BrowseTransactionsView: View {

    // MARK: --- Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.undoManager) private var undoManager
    @Environment(AppState.self) var appState

    // MARK: --- Local State
    @State private var ascending: Bool = true
    @State private var mergeCandidates: [Transaction] = []
    @State private var selectedTransaction: Transaction?
    @State private var selectedTransactionIDs = Set<NSManagedObjectID>()
    @State private var showingDeleteConfirmation = false
    @State private var showingEditTransactionView = false
    @State private var sortColumn: SortColumn = .transactionDate
    @State private var transactionsToDelete: Set<NSManagedObjectID> = []
    @State private var showMergeSheet = false

    // MARK: --- Injected Properties
    @FetchRequest private var transactions: FetchedResults<Transaction>

    init(predicate: NSPredicate? = nil) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
    }

    init(predicate: NSPredicate) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
    }

    // MARK: --- Derived Rows
    private var transactionRows: [TransactionRow] {
        let rows = transactions.map { TransactionRow(transaction: $0) }
        return rows.sorted { lhs, rhs in
            if let l = sortColumn.stringKey(for: lhs),
               let r = sortColumn.stringKey(for: rhs) {
                let cmp = l.localizedCompare(r)
                return ascending ? cmp == .orderedAscending : cmp == .orderedDescending
            }
            return false
        }
    }

    // MARK: --- Body
    var body: some View {
        VStack(spacing: 0) {
            transactionsTable
            statusBar
        }
        .toolbar { toolbarItems }
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
}

// MARK: --- BrowseTransactionsView Extensions
extension BrowseTransactionsView {

    // MARK: --- ContextMenu
    @ViewBuilder
    private func contextMenu(for row: TransactionRow) -> some View {
        if selectedTransactionIDs.contains(row.id) {

            // Edit Transaction
            if selectedTransactionIDs.count == 1 {
                Button("Edit Transaction") {
                    appState.selectedTransactionID = row.id
                    appState.pushCentralView(.editTransaction(existingTransaction: row.transaction))
                    appState.refreshInspector()
                }
                .disabled(anySelectedTransactionClosed)
            }

            // Merge Transactions - when exactly two rows are selected
            if selectedTransactionIDs.count == 2 {
                Button("Merge Transactions") {
                    mergeCandidates = transactions.filter { selectedTransactionIDs.contains($0.objectID) }
                    appState.pushCentralView(.transactionMergeView(mergeCandidates))
                    appState.refreshInspector()
                }
                .disabled(anySelectedTransactionClosed)
                Divider()
            }

            // Delete Transaction(s)
            Button(role: .destructive) {
                transactionsToDelete = selectedTransactionIDs
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Transaction(s)", systemImage: "trash")
            }
            .disabled(anySelectedTransactionClosed)
        }
    }

    // MARK: --- MultiLineTableCell
    @ViewBuilder
    private func multiLineTableCell(_ content: String, for row: TransactionRow) -> some View {
        HStack {
            Text(content)
                .foregroundColor(row.transaction.closed ? .blue : (row.transaction.isValid() ? .primary : .red))
                .lineLimit(nil)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }

    // MARK: --- SortContextMenu
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

    // MARK: --- StatusBar
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

    // MARK: --- TableCell
    @ViewBuilder
    private func tableCell(_ content: String, for row: TransactionRow) -> some View {
        HStack {
            Text(content)
//                .foregroundColor(row.transaction.isValid() ? .primary : .red)
                .foregroundColor(row.transaction.closed ? .blue : (row.transaction.isValid() ? .primary : .red))
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }

    // MARK: --- TransactionsTable
    private var transactionsTable: some View {
        Table(transactionRows, selection: $selectedTransactionIDs) {
#if os(macOS)
            TableColumn("Payment Method") { row in tableCell(row.paymentMethod, for: row) }
                .width(min: 50, ideal: 80, max: 100)
            TableColumn("Date") { row in tableCell(row.transactionDate, for: row) }
                .width(min: 80, ideal: 100, max: 150)
            TableColumn("Amount") { row in multiLineTableCell(row.displayAmount, for: row) }
                .width(min: 120, ideal: 130, max: 150)
            TableColumn("Fx") { row in tableCell(row.exchangeRate, for: row) }
                .width(min: 50, ideal: 55, max: 60)
            TableColumn("Category") { row in tableCell(row.category, for: row) }
                .width(min: 50, ideal: 80, max: 100)
            TableColumn("Split") { row in multiLineTableCell(row.displaySplitAmount, for: row) }
                .width(min: 200, ideal: 200, max: 300)
            TableColumn("Payee") { row in tableCell(row.payee, for: row) }
                .width(min: 50, ideal: 100, max: 300)
#else
            TableColumn("Transaction") { row in tableCell(row.iOSRowForDisplay, for: row) }
#endif
        }
        .font(.system(.body, design: .monospaced))
        .frame(minHeight: 300)
        .tableStyle(.inset)
        .contextMenu { SortContextMenu() }
        .onChange(of: selectedTransactionIDs) { newSelection in
            if let firstID = newSelection.first {
                appState.selectedTransactionID = firstID
                appState.selectedInspectorView = .viewTransaction
            } else {
                selectedTransaction = nil
                appState.selectedTransactionID = nil
            }
        }
    }

    // MARK: --- ToolbarItems
    private var toolbarItems: some ToolbarContent {
        Group {
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
                Button { undoManager?.undo() } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!(undoManager?.canUndo ?? false))
            }
            ToolbarItem {
                Button { undoManager?.redo() } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!(undoManager?.canRedo ?? false))
            }
        }
    }

    // MARK: --- UpdateSortColumn
    private func updateSortColumn(_ column: SortColumn) {
        if sortColumn == column {
            ascending.toggle()
        } else {
            sortColumn = column
            ascending = true
        }
        selectedTransactionIDs.removeAll()
    }

    // MARK: --- DeleteTransactions
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
                    DispatchQueue.main.async {
                        appState.refreshInspector() // AFTER the save
                    }
                }
                undoManager?.setActionName("Delete Transactions")
            } catch {
                print("Failed to delete transactions: \(error.localizedDescription)")
                viewContext.rollback()
            }
        }
    }
}

// MARK: --- BrowseTransactionsView Helpers
extension BrowseTransactionsView {

    private var anySelectedTransactionClosed: Bool {
        selectedTransactionIDs.contains { id in
            guard let tx = transactions.first(where: { $0.objectID == id }) else { return false }
            return tx.closed
        }
    }
}

// MARK: --- FETCH HELPERS
extension BrowseTransactionsView {
    // Add any future fetch helper functions here, alphabetized
}
