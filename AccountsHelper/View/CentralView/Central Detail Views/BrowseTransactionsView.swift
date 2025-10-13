//
//  BrowseTransactionsView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 16/09/2025.
//

import Foundation
import SwiftUI
import CoreData
import ItMkLibrary

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
        var wip: String = transaction.txAmount.formattedAsCurrency( transaction.currency )
        if transaction.currency == .GBP {
            return wip
        } else {
#if os(macOS)
            return wip + "\n" + transaction.txAmountInGBP.formattedAsCurrency( .GBP )
#else
//            return wip + " " + transaction.txAmountInGBP.formattedAsCurrency( .GBP )
            return wip
#endif
        }
    }
    
    var displaySplitAmount: String {
        if transaction.splitAmount == Decimal(0) { return "" }

        var splitPart = transaction.splitAmount.formattedAsCurrency(transaction.currency) + " " + transaction.splitCategory.description
        var remainderPart = transaction.splitRemainderAmount.formattedAsCurrency(transaction.currency) + " " + transaction.splitRemainderCategory.description

    #if os(macOS)
            return splitPart + "\n" + remainderPart
    #else
            return splitPart + remainderPart
    #endif

    }

    // MARK: --- Explanation
    var explanation: String { transaction.explanation ?? "" }

    // MARK: --- iOSRowForDisplay
    var iOSRowForDisplay: String {
        var parts: [String] = []
        if !transactionDate.isEmpty { parts.append("\(transactionDate) \(transaction.paymentMethod.description)" ) }
        if !displayAmount.isEmpty { parts.append("\(displayAmount) \(payee): \(category)"  ) }
//        if !payee.isEmpty && !category.isEmpty { parts.append("\(payee): \(category)") }
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
        let amount = transaction.splitRemainderAmount
        return amount.string2f
    }

    // MARK: --- SplitRemainderCategory
    var splitRemainderCategory: String { transaction.splitRemainderCategory.description }

    // MARK: --- TransactionDate
    var transactionDate: String { transaction.transactionDateAsString() ?? "" }

    // MARK: --- TxAmount
    var txAmount: String { transaction.txAmountAsString() ?? "" }

    // MARK: --- ExchangeRate
    var exchangeRate: String { transaction.currency == .GBP ? "" : (transaction.exchangeRateAsString() ?? "") }

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

    // MARK: --- State
    @State private var ascending: Bool = true
    @State private var mergeCandidates: [Transaction] = []
    @State private var selectedTransaction: Transaction?
    @State private var selectedTransactionIDs = Set<NSManagedObjectID>()
    @State private var showingDeleteConfirmation = false
    @State private var showingEditTransactionView = false
    @State private var sortColumn: SortColumn = .transactionDate
    @State private var transactionsToDelete: Set<NSManagedObjectID> = []
    @State private var showMergeSheet = false
    // Filter State
    @State private var selectedAccountingPeriod: AccountingPeriod? = nil
    @State private var selectedPaymentMethod: PaymentMethod? = nil
    

    // MARK: --- Injected Properties
    @FetchRequest private var transactions: FetchedResults<Transaction>

    // MARK: --- CoreData
    init(predicate: NSPredicate? = nil) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
            predicate: predicate
        )
    }
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Reconciliation.periodYear, ascending: false),
            NSSortDescriptor(keyPath: \Reconciliation.periodMonth, ascending: false)
        ],
        animation: .default
    )
    
    private var reconciliations: FetchedResults<Reconciliation>
    
    private var accountingPeriods: [AccountingPeriod] {
        var uniquePeriods = Set<AccountingPeriod>()
        for rec in reconciliations {
            uniquePeriods.insert(rec.accountingPeriod)
        }
        return Array(uniquePeriods).sorted(by: {
            ($0.year, $0.month) > ($1.year, $1.month)
        })
    }
    

    // MARK: --- Derived Rows
    private var transactionRows: [TransactionRow] {
        transactions.map { TransactionRow(transaction: $0) }
            .sorted { lhs, rhs in
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
            filterBar
            transactionsTable
            statusBar
        }
        .toolbar { toolbarItems }
        .onChange(of: selectedAccountingPeriod) { _, _ in refreshFetchRequest() }
        .onChange(of: selectedPaymentMethod) { _, _ in refreshFetchRequest() }
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
#if os(iOS)
        .sheet(isPresented: $showingEditTransactionView) {
            Text("EDIT HERE\(selectedTransactionIDs.first)")
            if selectedTransactionIDs.first != nil {
                AddOrEditTransactionView(transactionID: selectedTransactionIDs.first, context: viewContext )
            } else {
                Text("No transaction selected")
            }
        }
#endif
    }
}

// MARK: --- Subviews & Helpers
extension BrowseTransactionsView {

    // MARK: --- ContextMenu
    @ViewBuilder
    private func contextMenu(for row: TransactionRow) -> some View {
        if selectedTransactionIDs.contains(row.id) {

            if selectedTransactionIDs.count == 1 {
                Button("Edit Transaction") {
                    appState.selectedTransactionID = row.id
                    appState.pushCentralView(.editTransaction(existingTransaction: row.transaction))
                    appState.refreshInspector()
                }
                .disabled(anySelectedTransactionClosed)
            }

            if selectedTransactionIDs.count == 2 {
                Button("Merge Transactions") {
                    mergeCandidates = transactions.filter { selectedTransactionIDs.contains($0.objectID) }
                    appState.pushCentralView(.mergeTransactionsView(mergeCandidates))
                    appState.refreshInspector()
                }
                .disabled(anySelectedTransactionClosed)
                Divider()
            }

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

    // MARK: --- TableCell
    @ViewBuilder
    private func tableCell(_ content: String, for row: TransactionRow) -> some View {
        HStack {
            Text(content)
                .foregroundColor(row.transaction.closed ? .blue : (row.transaction.isValid() ? .primary : .red))
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }

    // MARK: --- TransactionsTable
    private var transactionsTable: some View {
        Table(filteredTransactionRows, selection: $selectedTransactionIDs) {
#if os(macOS)
            TableColumn("Payment Method") { tableCell($0.paymentMethod, for: $0) }
                .width(min: 50, ideal: 80, max: 100)
            TableColumn("Date") { tableCell($0.transactionDate, for: $0) }
                .width(min: 90, ideal: 100, max: 150)
            TableColumn("Amount") { multiLineTableCell($0.displayAmount, for: $0) }
                .width(min: 130, ideal: 130, max: 150)
            TableColumn("Fx") { tableCell($0.exchangeRate, for: $0) }
                .width(min: 50, ideal: 55, max: 60)
            TableColumn("Category") { tableCell($0.category, for: $0) }
                .width(min: 90, ideal: 80, max: 100)
            TableColumn("Split") { multiLineTableCell($0.displaySplitAmount, for: $0) }
                .width(min: 200, ideal: 200, max: 300)
            TableColumn("Payee") { tableCell($0.payee, for: $0) }
                .width(min: 50, ideal: 100, max: 300)
#else
            TableColumn("Transaction") { row in
                tableCell(row.iOSRowForDisplay, for: row)
                    .onTapGesture {
                        selectedTransactionIDs = [row.id]
                    }
            }
#endif
        }
//        .font(.system(.body, design: .monospaced))
        #if os(macOS)
        .font(.custom("SF Mono Medium", size: 14))
        #else
        .font(.custom("SF Mono Medium", size: 15))
        #endif
        .frame(minHeight: 300)
        .tableStyle(.inset)
        .contextMenu { SortContextMenu() }
        .onChange(of: selectedTransactionIDs) { _, newSelection in
            if let firstID = newSelection.first {
                appState.selectedTransactionID = firstID
                appState.selectedInspectorView = .viewTransaction
            } else {
                selectedTransaction = nil
                appState.selectedTransactionID = nil
            }
        }
    }

    // MARK: --- SortContextMenu
    @ViewBuilder
    private func SortContextMenu() -> some View {
#if os(iOS)
        Button {
            //            appState.selectedTransactionID = selectedTransactionIDs.first
            showingEditTransactionView = true
        } label: {
            Label("Edit", systemImage: "circle.badge.xmark")
        }
#endif
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
        .background(Color.ItMkPlatformWindowBackgroundColor)
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
            // MARK: --- Filter Menu
            ToolbarItem {
                Menu {
                    // Accounting Period Picker
                    Picker("Accounting Period", selection: $selectedAccountingPeriod) {
                        Text("All").tag(nil as AccountingPeriod?)
                        ForEach(uniqueAccountingPeriods, id: \.self) { period in
                            Text(period.displayStringWithOpening).tag(period as AccountingPeriod?)
                        }
                    }
                    
                    // Payment Method Picker
                    Picker("Payment Method", selection: $selectedPaymentMethod) {
                        Text("All").tag(nil as PaymentMethod?)
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.description).tag(method as PaymentMethod?)
                        }
                    }
                } label: {
                    Label("Filters", systemImage: "line.horizontal.3.decrease.circle")
                }
            }
        }
    }

    // MARK: --- Helpers
    private func updateSortColumn(_ column: SortColumn) {
        if sortColumn == column {
            ascending.toggle()
        } else {
            sortColumn = column
            ascending = true
        }
        selectedTransactionIDs.removeAll()
    }

    private var anySelectedTransactionClosed: Bool {
        selectedTransactionIDs.contains { id in
            guard let tx = transactions.first(where: { $0.objectID == id }) else { return false }
            return tx.closed
        }
    }

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
                        appState.refreshInspector()
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

// MARK: --- FILTERING
extension BrowseTransactionsView {
    
    // MARK: --- BuildPredicate
    private func buildPredicate() -> NSPredicate? {
        var predicates: [NSPredicate] = []

        // --- Payment Method Filter
        if let method = selectedPaymentMethod {
            predicates.append(NSPredicate(format: "paymentMethodCD == %@", NSNumber(value: method.rawValue)))
        }

        // --- Accounting Period / Date Filter
        if let method = selectedPaymentMethod, let period = selectedAccountingPeriod {
            if let reconciliation = try? Reconciliation.fetchOne(for: period, paymentMethod: method, context: viewContext) {
                let start = reconciliation.transactionStartDate as NSDate
                let end = reconciliation.transactionEndDate as NSDate
                predicates.append(NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start, end))
            }
        }

        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    
    // MARK: --- RefreshFetchRequest
    private func refreshFetchRequest() {
        transactions.nsPredicate = buildPredicate()
    }

        // MARK: --- FilterBar
    // MARK: --- FilterBar
    private var filterBar: some View {
        HStack(spacing: 16) {
            // --- Payment Method Picker
            Picker("Payment Method", selection: $selectedPaymentMethod) {
                Text("All").tag(nil as PaymentMethod?)
                ForEach(PaymentMethod.allCases.filter { $0 != .unknown }, id: \.self) { method in
                    Text(method.description).tag(method as PaymentMethod?)
                }
            }
            .pickerStyle(MenuPickerStyle())

            // --- Accounting Period Picker (only show if a payment method is selected)
            if let method = selectedPaymentMethod {
                Picker("Period", selection: $selectedAccountingPeriod) {
                    Text("All").tag(nil as AccountingPeriod?)
                    
                    // Only show periods that have reconciliations for this method
                    ForEach(accountingPeriodsForPaymentMethod(method), id: \.self) { period in
                        Text(period.displayStringWithOpening).tag(Optional(period))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.ItMkPlatformWindowBackgroundColor)
    }

    // MARK: --- Unique Accounting Periods
    private var uniqueAccountingPeriods: [AccountingPeriod] {
        let periods = transactions.compactMap { transaction -> AccountingPeriod? in
            guard let date = transaction.transactionDate else { return nil }
            let comps = Calendar.current.dateComponents([.year, .month], from: date)
            guard let year = comps.year, let month = comps.month else { return nil }
            return AccountingPeriod(year: year, month: month)
        }
        return Array(Set(periods)).sorted { lhs, rhs in
            if lhs.year != rhs.year { return lhs.year < rhs.year }
            return lhs.month < rhs.month
        }
    }
    
    // MARK: --- Accounting periods per payment method
    private func accountingPeriodsForPaymentMethod(_ method: PaymentMethod) -> [AccountingPeriod] {
        let periods = reconciliations
            .filter { $0.paymentMethod == method }
            .map { $0.accountingPeriod }
        return Array(Set(periods))
            .sorted { ($0.year, $0.month) > ($1.year, $1.month) }
    }
    
    // MARK: --- FilteredTransactionRows
    private var filteredTransactionRows: [TransactionRow] {
        let predicate = buildPredicate()
        
        // Convert to array first
        let allTransactions = Array(transactions)
        
        let filtered = predicate == nil ? allTransactions : allTransactions.filter { predicate!.evaluate(with: $0) }
        
        return filtered.map { TransactionRow(transaction: $0) }
            .sorted { lhs, rhs in
                if sortColumn == .transactionDate {
                    guard let lDate = lhs.transaction.transactionDate,
                          let rDate = rhs.transaction.transactionDate else { return false }
                    return ascending ? (lDate < rDate) : (lDate > rDate)
                } else if let l = sortColumn.stringKey(for: lhs),
                          let r = sortColumn.stringKey(for: rhs) {
                    let cmp = l.localizedCompare(r)
                    return ascending ? cmp == .orderedAscending : cmp == .orderedDescending
                }
                return false
            }
    }
}
