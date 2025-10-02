//
//  BrowseTransactionsView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 16/09/2025.
//
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

    // All stringified through extensions or safe unwraps
    var category: String { transaction.category.description }
    var splitCategory: String { transaction.splitCategory.description }
    var splitRemainderCategory: String { transaction.splitRemainderCategory.description }
    var currency: String { transaction.currency.description }
    var debitCredit: String { transaction.debitCredit.description }

    var transactionDate: String { transaction.transactionDateAsString() ?? "" }
    var txAmount: String { transaction.txAmountAsString() ?? "" }
    var exchangeRate: String { transaction.exchangeRateAsString() ?? "" }

    var paymentMethod: String { transaction.paymentMethod.description }
    var payee: String { transaction.payee ?? "" }
    var payer: String { transaction.payer.description }
    var explanation: String { transaction.explanation ?? "" }

    // Derived formatting
    var displayAmount: String {
        let rawAmount = NSDecimalNumber(decimal: transaction.txAmount)
        let rawFx = NSDecimalNumber(decimal: transaction.exchangeRate)

        let txAmount: Double = rawAmount.doubleValue
        let exchangeRate: Double = rawFx.doubleValue
        let txAmountGBP: Double = txAmount / (exchangeRate == Double(0) ? Double(1) : exchangeRate)

        let formattedAmount: String
        let formattedAmountGBP = String(format: "%.2f", txAmountGBP)

        if transaction.currency == .JPY {
            formattedAmount = String(format: "%.0f", txAmount)
        } else {
            formattedAmount = String(format: "%.2f", txAmount)
        }

        var resultWIP = "\(currency) \(formattedAmount) \(transaction.debitCredit == .DR ? debitCredit : "")"
        if transaction.currency == .GBP {
            return resultWIP
        } else {
            #if os(macOS)
            return resultWIP + "\nGBP \(formattedAmountGBP)"
            #else
            return resultWIP + " GBP \(formattedAmountGBP)"
            #endif
        }
    }
    
    var displaySplitAmount: String {
        
        if transaction.splitAmount == Decimal(0) { return "" }
        
        let rawSplitAmount = NSDecimalNumber(decimal: transaction.splitAmount).doubleValue
        let rawRemainderAmount = NSDecimalNumber(decimal: transaction.splitRemainderAmount).doubleValue
        
        var formattedSplitAmount: String = ""
        var formattedRemainderAmount: String = ""
        if transaction.currency == .JPY {
            formattedSplitAmount = String(format: "%.0f", rawSplitAmount )
            formattedRemainderAmount = String(format: "%.0f", rawRemainderAmount )
        } else {
            formattedSplitAmount = String(format: "%.2f", rawSplitAmount )
            formattedRemainderAmount = String(format: "%.2f", rawRemainderAmount )
        }
        var splitAmountPad = String(repeating: " ", count: max(0, 5 - formattedSplitAmount.count))
        var remainderAmountPad = String(repeating: " ", count: max(0, 5 - formattedRemainderAmount.count))
        var resultWIP = "\(currency) \(formattedSplitAmount)" + splitAmountPad + " \(splitCategory)"
        resultWIP += "\n\(currency) \(formattedRemainderAmount)" + remainderAmountPad + " \(splitRemainderCategory)"
        
        return resultWIP
    }
    
    var splitRemainderAsString: String {
        guard let amount = transaction.splitRemainderAmount as? NSDecimalNumber else { return "" }
        return String(format: "%.2f", amount.doubleValue)
    }

    static func == (lhs: TransactionRow, rhs: TransactionRow) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: --- iOS Formatting
    // iOS shows only one table column so we just construct what we want to see here

    var iOSRowForDisplay: String {
        var parts: [String] = []
        if !transactionDate.isEmpty {
            parts.append(transactionDate)
        }
        if !displayAmount.isEmpty {
            parts.append(displayAmount)
        }
        if !payee.isEmpty && !category.isEmpty {
            parts.append("\(payee): \(category)")
        }
        return parts.joined(separator: "\n")
        
    }
}

// MARK: - SortColumn
enum SortColumn: CaseIterable, Identifiable {
    case category, splitCategory, currency, debitCredit, exchangeRate,
         explanation, payee, payer, paymentMethod, splitAmount, transactionDate, txAmount

    var id: Self { self }

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

    fileprivate func stringKey(for row: TransactionRow) -> String? {
        switch self {
        case .category:       return row.category
        case .splitCategory:  return row.splitCategory
        case .currency:       return row.currency
        case .debitCredit:    return row.debitCredit
        case .payee:          return row.payee
        case .payer:          return row.payer
        case .paymentMethod:  return row.paymentMethod
        case .explanation:    return row.explanation
        case .transactionDate:return row.transactionDate
        case .txAmount:       return row.txAmount
        case .exchangeRate:   return row.exchangeRate
        default:              return nil
        }
    }
}

// MARK: - BrowseTransactionsView
struct BrowseTransactionsView: View {
    
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
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.undoManager) private var undoManager
    @Environment(AppState.self) var appState


    @State private var selectedTransactionIDs = Set<NSManagedObjectID>()
    @State private var selectedTransaction: Transaction?
    @State private var showingEditTransactionView = false
    @State private var showingDeleteConfirmation = false
    @State private var transactionsToDelete: Set<NSManagedObjectID> = []

    // Sorting state
    @State private var sortColumn: SortColumn = .transactionDate
    @State private var ascending: Bool = true
    
    // Merging State
    @State private var showMergeSheet = false
    @State private var mergeCandidates: [Transaction] = []


    // MARK: - Derived Rows
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

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            transactionsTable
            statusBar
        }
        .toolbar { toolbarItems }
//        .sheet(isPresented: $showingEditTransactionView) {
//            EditTransactionView(transaction: selectedTransaction)
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

    // MARK: - Transactions Table
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
//            TableColumn("Amount") { row in tableCell(row.displayAmount, for: row) }
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

    private func updateSortColumn(_ column: SortColumn) {
        if sortColumn == column {
            ascending.toggle()
        } else {
            sortColumn = column
            ascending = true
        }
        selectedTransactionIDs.removeAll()
    }

    // MARK: - StatusBar
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

    // MARK: - Toolbar
    private var toolbarItems: some ToolbarContent {
        Group {
//            ToolbarItem(placement: .navigation) { 
//                Button { appState.popCentralView()
//                } label: {
//                    Label("Back", systemImage: "chevron.left")
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

    // MARK: - Table Cell Helpers
    @ViewBuilder
    private func tableCell(_ content: String, for row: TransactionRow) -> some View {
        HStack {
            Text(content)
                .foregroundColor(row.transaction.isValid() ? .primary : .red)
            Spacer()
        }
    
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }
    
    @ViewBuilder
    private func multiLineTableCell(_ content: String, for row: TransactionRow) -> some View {
        HStack {
            Text(content)
                .lineLimit(nil)
            Spacer()
        }
    
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }

    // MARK: - Context Menu (for Row)
    @ViewBuilder
    private func contextMenu(for row: TransactionRow) -> some View {
        if selectedTransactionIDs.contains(row.id) {
            // Edit Transaction
            if selectedTransactionIDs.count == 1 {
                Button("Edit Transaction") {
                    appState.selectedTransactionID = row.id
                    appState.pushCentralView(.editTransaction( existingTransaction: row.transaction ) )
                }
            }

            // Merge Transactions - when exactly two rows are selected
            if selectedTransactionIDs.count == 2 {
                Button("Merge Transactions") {
                    mergeCandidates = transactions.filter { selectedTransactionIDs.contains($0.objectID) }
                    appState.pushCentralView( .transactionMergeView( mergeCandidates ) )
                }
                Divider()
            }
                    
            // Delete Transaction(s)
            Button(role: .destructive) {
                transactionsToDelete = selectedTransactionIDs
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Transaction(s)", systemImage: "trash")
            }
        }
    }

    // MARK: - Delete with Undo Support
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
