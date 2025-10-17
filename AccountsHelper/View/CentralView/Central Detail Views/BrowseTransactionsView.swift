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
#if os(macOS)
import AppKit
typealias UIRectCorner = CACornerMask
#else
import UIKit
#endif

// MARK: --- To work aroound a SwiftUI bug
fileprivate func safeUIUpdate(_ action: @escaping () -> Void) {
    action()
//    DispatchQueue.main.async {
//        withAnimation(.none) {
//            action()
//        }
//    }
}


// MARK: --- SortColumn
enum SortColumn: CaseIterable, Identifiable {
    case category, currency, debitCredit, exchangeRate,
         payee, payer, paymentMethod, transactionDate, txAmount

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .transactionDate: return "calendar"
        case .category:        return "folder"
        case .currency:        return "dollarsign.circle"
        case .debitCredit:     return "arrow.left.arrow.right"
        case .exchangeRate:    return "chart.line.uptrend.xyaxis"
        case .paymentMethod:   return "creditcard"
        case .payee:           return "person"
        case .payer:           return "person.crop.circle"
        case .txAmount:        return "sum"
        }
    }

    var title: String {
        switch self {
        case .category:        return "Category"
        case .currency:        return "Currency"
        case .debitCredit:     return "Debit/Credit"
        case .exchangeRate:    return "Fx"
        case .payee:           return "Payee"
        case .payer:           return "Payer"
        case .paymentMethod:   return "Payment Method"
        case .transactionDate: return "Date"
        case .txAmount:        return "Amount"
        }
    }

    fileprivate func stringKey(for row: TransactionRow) -> String? {
        switch self {
        case .category:        return row.category
        case .currency:        return row.currency
        case .debitCredit:     return row.debitCredit
        case .payee:           return row.payee
        case .payer:           return row.payer
        case .paymentMethod:   return row.paymentMethod
        case .transactionDate: return row.transactionDate
        case .txAmount:        return row.txAmount
        case .exchangeRate:    return row.exchangeRate
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
    // Focus State
    @FocusState private var focusedRowIndex: Int?
    // Sort State
    @State private var ascending: Bool = true
    @State private var sortColumn: SortColumn = .transactionDate
    // Merge State
    @State private var mergeCandidates: [Transaction] = []
    // Selection State
    @State private var selectedTransaction: Transaction?
    @State private var selectedTransactionIDs = Set<NSManagedObjectID>()
    @State private var lastClickedRowIndex: Int? = nil
    // Dialogs etc State
    @State private var showingDeleteConfirmation = false
    @State private var showingEditTransactionView = false
    @State private var showMergeSheet = false
    // Delete State
    @State private var transactionsToDelete: Set<NSManagedObjectID> = []
    // Filter State
    @State private var selectedAccountingPeriod: AccountingPeriod? = nil
    @State private var selectedPaymentMethod: PaymentMethod? = nil
    // Column Width State
    #if os(macOS)
    @State private var availableWidth: CGFloat = 0
    @State private var scaledColumnWidths: [String: CGFloat] = [:]
    @State private var columnWidths: [String: CGFloat] = [
        "Payment Method": 80,
        "Date": 100,
        "Amount": 130,
        "Balance": 130,
        "Fx": 60,
        "Category": 80,
        "Split": 200,
        "Payee": 300
    ]
    #endif

    // MARK: --- Injected Properties
    @FetchRequest private var transactions: FetchedResults<Transaction>

    // MARK: --- CoreData
    init(predicate: NSPredicate? = nil) {
        _transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.transactionDate, ascending: true)],
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
    }

    // MARK: --- Body
    var body: some View {
        VStack(spacing: 0) {
            filterBar
            transactionsTable
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            statusBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarItems }
        .onChange(of: selectedAccountingPeriod) { _, _ in
            safeUIUpdate {
                refreshFetchRequest()
            }
        }
        .onChange(of: selectedPaymentMethod) { _, _ in
            safeUIUpdate {
                refreshFetchRequest()
            }
        }
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
                    safeUIUpdate { selectedTransactionIDs = [row.id] }
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
                safeUIUpdate {
                    transactionsToDelete = selectedTransactionIDs
                    showingDeleteConfirmation = true
                }
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
                .foregroundColor(
                    selectedTransactionIDs.contains(row.id)
                    ? .white // selected row text
                    : (row.transaction.closed ? .blue : (row.transaction.isValid() ? .primary : .red))
                )
                .lineLimit(2)
                .truncationMode(.tail)
            Spacer()
        }
        .padding(.leading, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }

    // MARK: --- TableCell
    @ViewBuilder
    private func tableCell(_ content: String, for row: TransactionRow) -> some View {
        HStack {
            Text(content)
                .foregroundColor(
                    selectedTransactionIDs.contains(row.id)
                    ? .white // selected row text
                    : (row.transaction.closed ? .blue : (row.transaction.isValid() ? .primary : .red))
                )
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .padding(.leading, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu { contextMenu(for: row) }
    }

    // MARK: --- TransactionsTable
    private var transactionsTable: some View {
        #if os(macOS)
        GeometryReader { proxy in
            
//            let availableWidth = proxy.size.width
            let width = proxy.size.width
            
            Color.clear // or any invisible view to attach `.onAppear` / `.onChange`
                .onAppear {
                    // only set once on first appear
                    if availableWidth != width {
                        availableWidth = width
                        updateScaledWidths(for: width)
                    }
                }
                .onChange(of: width) { newWidth in
                    availableWidth = newWidth
                    updateScaledWidths(for: newWidth)
                }
            
            VStack(spacing: 0) {
                // --- Header Row
                HStack(spacing: 0) {
                    TableHeaderCell("Payment Method", width: 80)
                        .frame(width: scaledColumnWidths["Payment Method"] ?? 80)
                    TableHeaderCell("Date", width: 100)
                        .frame(width: scaledColumnWidths["Date"] ?? 100)
                    TableHeaderCell("Amount", width: 130)
                        .frame(width: scaledColumnWidths["Amount"] ?? 130)
                    TableHeaderCell("Balance", width: 130)
                        .frame(width: scaledColumnWidths["Balance"] ?? 130)
                    TableHeaderCell("Fx", width: 60)
                        .frame(width: scaledColumnWidths["Fx"] ?? 60)
                    TableHeaderCell("Category", width: 80)
                        .frame(width: scaledColumnWidths["Category"] ?? 80)
                    TableHeaderCell("Split", width: 200)
                        .frame(width: scaledColumnWidths["Split"] ?? 200)
                    TableHeaderCell("Payee", width: 100)
                        .frame(width: scaledColumnWidths["Payee"] ?? 100)
                }
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // --- Rows
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredTransactionRows.enumerated()), id: \.element.id) { index, row in
                            TransactionRowView(
                                row: row,
                                selectedTransactionIDs: $selectedTransactionIDs,
                                anySelectedTransactionClosed: anySelectedTransactionClosed,
                                appState: appState,
                                index: index
                            )
                            .background(rowBackground(for: index, row: row))
                            .focusable(true)
                            .focused($focusedRowIndex, equals: index)
                            .onTapGesture { focusedRowIndex = index }
                            .onMoveCommand { direction in
                                switch direction {
                                case .up:
                                    if let current = focusedRowIndex, current > 0 {
                                        focusedRowIndex = current - 1
                                    }
                                case .down:
                                    if let current = focusedRowIndex,
                                       current < filteredTransactionRows.count - 1 {
                                        focusedRowIndex = current + 1
                                    }
                                default: break
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 300)
            }
            .onAppear {
                updateScaledWidths(for: availableWidth)
            }
            .onChange(of: availableWidth) { _, newWidth in
                updateScaledWidths(for: newWidth)
            }
            // --- Constrain VStack to the width of the available window
            .frame(minWidth: proxy.size.width, alignment: .leading)
        }
        .contextMenu { SortContextMenu() }
        .onChange(of: selectedTransactionIDs) { _, newSelection in
            safeUIUpdate {
                if let firstID = newSelection.first {
                    appState.selectedTransactionID = firstID
                    appState.selectedInspectorView = .viewTransaction
                } else {
                    selectedTransaction = nil
                    appState.selectedTransactionID = nil
                }
            }
        }
        #endif
    }
    
    // MARK: --- UpdateScaledWidths
    private func updateScaledWidths(for availableWidth: CGFloat) {
        let minWidth: CGFloat = 60
        let totalRequested = columnWidths.values.reduce(0, +)

        // Scale to fit availableWidth proportionally
        let scaleFactor = availableWidth / totalRequested
        scaledColumnWidths = columnWidths.mapValues { max(minWidth, $0 * scaleFactor) }

        // Debug
        print("Scaled column widths: \(scaledColumnWidths)")
    }



    // MARK: --- ResizeColumn
    private func resizeColumn(title: String, delta: CGFloat) {
        guard let currentWidth = columnWidths[title] else { return }
        guard availableWidth > 0 else { return }
        
        let minWidth: CGFloat = 60
        let newWidth = max(minWidth, currentWidth + delta)

        columnWidths[title] = newWidth

        // Ensure total width does not exceed availableWidth
        let totalWidth = columnWidths.values.reduce(0, +)
        if totalWidth > availableWidth {
            // Pick last column to shrink (or any chosen column)
            let shrinkKey = "Payee"
            if shrinkKey != title, let current = columnWidths[shrinkKey] {
                let excess = totalWidth - availableWidth
                columnWidths[shrinkKey] = max(minWidth, current - excess)
            }

        }

        scaledColumnWidths = columnWidths
    }

    
//    private func resizeColumn(title: String, delta: CGFloat) {
//        
//        guard let currentWidth = scaledColumnWidths[title] else { return }
//        
//        let newWidth = max(60, currentWidth + delta)
//        
//        columnWidths[title] = newWidth
//        scaledColumnWidths[title] = newWidth
//    }


//    private var transactionsTable: some View {
//        #if os(macOS)
//        GeometryReader { proxy in
////            ScrollView(.horizontal) { // horizontal scroll
//                VStack(spacing: 0) {
//                    // --- Header Row
//                    HStack(spacing: 0) {
//                        TableHeaderCell("Payment Method", width: 80)
//                        TableHeaderCell("Date", width: 100)
//                        TableHeaderCell("Amount", width: 130)
//                        TableHeaderCell("Balance", width: 130)
//                        TableHeaderCell("Fx", width: 60)
//                        TableHeaderCell("Category", width: 80)
//                        TableHeaderCell("Split", width: 200)
//                        TableHeaderCell("Payee", width: 100)
//                    }
//                    .background(Color.gray.opacity(0.1))
//                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//                    
//                    // --- Rows in vertical ScrollView
//                    ScrollView(.vertical) {
//                        LazyVStack(spacing: 0) {
//                            ForEach(Array(filteredTransactionRows.enumerated()), id: \.element.id) { index, row in
//                                TransactionRowView(
//                                    row: row,
//                                    selectedTransactionIDs: $selectedTransactionIDs,
//                                    anySelectedTransactionClosed: anySelectedTransactionClosed,
//                                    appState: appState,
//                                    index: index
//                                )
//                                .background(rowBackground(for: index, row: row))
//                            }
//                        }
//                    }
//                    .frame(minHeight: 300)
//                }
//                // --- Make VStack at least as wide as the available window
//                .frame(minWidth: proxy.size.width, alignment: .leading)
//           }
//            // --- Make the horizontal scroll expand to full width
////            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
////        }
//        .contextMenu { SortContextMenu() }
//        .onChange(of: selectedTransactionIDs) { _, newSelection in
//            safeUIUpdate {
//                if let firstID = newSelection.first {
//                    appState.selectedTransactionID = firstID
//                    appState.selectedInspectorView = .viewTransaction
//                } else {
//                    selectedTransaction = nil
//                    appState.selectedTransactionID = nil
//                }
//            }
//        }
//        #endif
//    }

    // MARK: --- TransactionRowView
    @ViewBuilder
    private func TransactionRowView(
        row: TransactionRow,
        selectedTransactionIDs: Binding<Set<NSManagedObjectID>>,
        anySelectedTransactionClosed: Bool,
        appState: AppState,
        index: Int
    ) -> some View {
        #if os(macOS)
        HStack(spacing: 0) {
            tableCell(row.paymentMethod, for: row)
                .frame(width: scaledColumnWidths["Payment Method"] ?? 80)
            tableCell(row.transactionDate, for: row)
                .frame(width: scaledColumnWidths["Date"] ?? 100)
            multiLineTableCell(row.displayAmount, for: row)
                .frame(width: scaledColumnWidths["Amount"] ?? 130)
            tableCell(row.runningBalance.formattedAsCurrency(.GBP), for: row)
                .frame(width: scaledColumnWidths["Balance"] ?? 130)
            tableCell(row.exchangeRate, for: row)
                .frame(width: scaledColumnWidths["Fx"] ?? 60)
            tableCell(row.category, for: row)
                .frame(width: scaledColumnWidths["Category"] ?? 80)
            multiLineTableCell(row.displaySplitAmount, for: row)
                .frame(width: scaledColumnWidths["Split"] ?? 200)
            tableCell(row.payee, for: row)
                .frame(width: scaledColumnWidths["Payee"] ?? 100)
        }
        .padding(.leading, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            #if os(macOS)
            safeUIUpdate {
                let modifiers = NSEvent.modifierFlags
                let rowIndex = index

                if modifiers.contains(.command) {
                    // Cmd-click toggles selection
                    if selectedTransactionIDs.wrappedValue.contains(row.id) {
                        selectedTransactionIDs.wrappedValue.remove(row.id)
                    } else {
                        selectedTransactionIDs.wrappedValue.insert(row.id)
                    }
                    lastClickedRowIndex = rowIndex
                } else if modifiers.contains(.shift), let lastIndex = lastClickedRowIndex {
                    // Shift-click selects range
                    let minIndex = min(lastIndex, rowIndex)
                    let maxIndex = max(lastIndex, rowIndex)
                    let rangeIDs = filteredTransactionRows[minIndex...maxIndex].map { $0.id }
                    selectedTransactionIDs.wrappedValue.formUnion(rangeIDs)
                } else {
                    // Regular click selects single row
                    selectedTransactionIDs.wrappedValue = [row.id]
                    lastClickedRowIndex = rowIndex
                }
            }
            #else
            safeUIUpdate { selectedTransactionIDs.wrappedValue = [row.id] }
            #endif
        }

        .contextMenu { contextMenu(for: row) }
        #else
        tableCell(row.iOSRowForDisplay, for: row)
            .contentShape(Rectangle())
            .onTapGesture {
                safeUIUpdate { selectedTransactionIDs.wrappedValue = [row.id] }
            }
            .contextMenu { contextMenu(for: row) }
        #endif
    }

    // MARK: --- TableHeaderCell (macOS only)
    #if os(macOS)
@ViewBuilder
    private func TableHeaderCell(_ title: String, width: CGFloat) -> some View {
        let handleWidth: CGFloat = 4
        
        HStack(spacing: 0) {
            // --- Column title
            Text(title)
                .padding(.leading, 6)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.custom("SF Mono Medium", size: 14))
                .frame(width: (scaledColumnWidths[title] ?? width) - handleWidth, height: 28, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .border(Color.gray.opacity(0.3), width: 0.5)
            
            // --- Drag handle
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: handleWidth, height: 28)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
//                            let val2 = (value.translation.width > 0 ? 1 : -1 )
//                            resizeColumn(title: title, delta: CGFloat(val2))
                            resizeColumn(title: title, delta: value.translation.width)
                        }
                )
                .onHover { hovering in
                    NSCursor.resizeLeftRight.set()
                    if !hovering { NSCursor.arrow.set() }
                }
        }
        .frame(width: scaledColumnWidths[title] ?? width, height: 28)
    }
#endif

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
                    safeUIUpdate {
                        transactionsToDelete = selectedTransactionIDs
                        showingDeleteConfirmation = true
                    }
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
        // Defer the change to avoid mutating the table's data while AppKit/SwiftUI
        // are mid-update (this avoids the NSIndexSet enumerateIndexesInRange crash).
        DispatchQueue.main.async {
            // Prevent SwiftUI animated diffs which sometimes cause internal indexset issues.
            withAnimation(.none) {
                if sortColumn == column {
                    ascending.toggle()
                } else {
                    sortColumn = column
                    ascending = true
                }
                safeUIUpdate {
                    selectedTransactionIDs.removeAll()
                }
            }
        }
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
                safeUIUpdate {
                    selectedTransactionIDs.removeAll()
                }

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
        safeUIUpdate {
            transactions.nsPredicate = buildPredicate()
        }
    }
    
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
        let allTransactions = Array(transactions)
        let filtered = predicate == nil ? allTransactions : allTransactions.filter { predicate!.evaluate(with: $0) }
        
        // Map to rows
        var rows = filtered.map { TransactionRow(transaction: $0) }
        
        // Sort rows
        rows.sort { lhs, rhs in
            switch sortColumn {
            case .transactionDate:
                guard let lDate = lhs.transaction.transactionDate,
                      let rDate = rhs.transaction.transactionDate else { return false }
                return ascending ? (lDate < rDate) : (lDate > rDate)
            case .txAmount:
                let lAmount = lhs.transaction.txAmountInGBP
                let rAmount = rhs.transaction.txAmountInGBP
                return ascending ? (lAmount < rAmount) : (lAmount > rAmount)
            default:
                if let l = sortColumn.stringKey(for: lhs),
                   let r = sortColumn.stringKey(for: rhs) {
                    let cmp = l.localizedCompare(r)
                    return ascending ? cmp == .orderedAscending : cmp == .orderedDescending
                }
                return false
            }
        }
        
        // MARK: --- Compute running balances (GBP only)
        if let paymentMethod = selectedPaymentMethod, sortColumn == .transactionDate {
            // Get previous reconciliation balance if available
            var balance: Decimal = 0
            if let previousRec = reconciliations
                .filter({ $0.paymentMethod == paymentMethod })
                .sorted(by: { ($0.periodYear, $0.periodMonth) > ($1.periodYear, $1.periodMonth) })
                .first {
                balance = previousRec.endingBalance
            }
            
            // Apply running balance
            for i in 0..<rows.count {
                rows[i].runningBalance = balance - rows[i].transaction.txAmountInGBP
                balance = rows[i].runningBalance
            }
        }
        
        return rows
    }
}

// MARK: --- VIEW HELPERS
extension BrowseTransactionsView {
    
    // Helper for the row background
    @ViewBuilder
    private func rowBackground(for index: Int, row: TransactionRow) -> some View {
        if selectedTransactionIDs.contains(row.id) {
            let prevSelected = index > 0 && selectedTransactionIDs.contains(filteredTransactionRows[index-1].id)
            let nextSelected = index < filteredTransactionRows.count-1 && selectedTransactionIDs.contains(filteredTransactionRows[index+1].id)
            let corners: RectCorner = {
                switch (prevSelected, nextSelected) {
                case (false, false): return .allCorners
                case (false, true): return [.topLeft, .topRight]
                case (true, false): return [.bottomLeft, .bottomRight]
                case (true, true): return []
                }
            }()
            Color.blue.opacity(1)
                .clipShape(RoundedCorner(corners: corners, radius: 8))
        } else if index % 2 == 0 {
            Color.gray.opacity(0.05)
        } else {
            Color.clear
        }
    }
    
    
    // MARK: --- RectCorner OptionSet
    struct RectCorner: OptionSet {
        let rawValue: Int
        
        static let topLeft     = RectCorner(rawValue: 1 << 0)
        static let topRight    = RectCorner(rawValue: 1 << 1)
        static let bottomLeft  = RectCorner(rawValue: 1 << 2)
        static let bottomRight = RectCorner(rawValue: 1 << 3)
        static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    }
    
    // MARK: --- RoundedCorner
    struct RoundedCorner: Shape {
        var corners: RectCorner
        var radius: CGFloat
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let tl = corners.contains(.topLeft) ? radius : 0
            let tr = corners.contains(.topRight) ? radius : 0
            let bl = corners.contains(.bottomLeft) ? radius : 0
            let br = corners.contains(.bottomRight) ? radius : 0
            
            path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
            
            // Top edge
            path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
            if tr > 0 {
                path.addArc(
                    center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                    radius: tr,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(0),
                    clockwise: false
                )
            }
            
            // Right edge
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
            if br > 0 {
                path.addArc(
                    center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                    radius: br,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false
                )
            }
            
            // Bottom edge
            path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
            if bl > 0 {
                path.addArc(
                    center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                    radius: bl,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false
                )
            }
            
            // Left edge
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
            if tl > 0 {
                path.addArc(
                    center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                    radius: tl,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false
                )
            }
            
            path.closeSubpath()
            return path
        }
    }
}

