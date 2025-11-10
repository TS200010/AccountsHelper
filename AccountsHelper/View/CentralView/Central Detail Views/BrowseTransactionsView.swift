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
import PrintingKit
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

// MARK: --- RectCorner OptionSet
struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft     = RectCorner(rawValue: 1 << 0)
    static let topRight    = RectCorner(rawValue: 1 << 1)
    static let bottomLeft  = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
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

    // MARK: --- Constants
    private let macOSRowHeight: CGFloat = 28
    
    // MARK: --- CoreData
    @FetchRequest private var transactions: FetchedResults<Transaction>

    // MARK: --- Initialiser
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
            #if os(macOS)
                .lineLimit(1)
                .truncationMode(.tail)
            #else
                .lineLimit(2)
            #endif
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
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Color.clear // or any invisible view to attach `.onAppear` / `.onChange`
                    .onAppear {
                        availableWidth = width
                        // Load saved widths
                        if let saved = UserDefaults.standard.dictionary(forKey: columnWidthsKey) as? [String: Double] {
                            columnWidths = saved.mapValues { CGFloat($0) }
                        }
                        updateScaledWidths(for: availableWidth)
                    }
                    .onChange(of: width) { _, newWidth in
                        availableWidth = newWidth
                        updateScaledWidths(for: newWidth)
                    }
                
                VStack(spacing: 0) {
                    // --- Header Row
                    ZStack{
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(white: 0.80)) // slightly darker
                            .frame(height: macOSRowHeight) // force exact row height
                            .padding(.leading, 8)
                            .if(gViewCheck) { view in view.border(.orange) }
                        
                        HStack(spacing: 0) {
                            TableHeaderCell("Payment Method", width: 80)
                                .frame(width: scaledColumnWidths["Payment Method"] ?? 80)
                                .if( gViewCheck ) { view in view.border( .green )}
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
                        .if( gViewCheck ) { view in view.border( .cyan )}
                    }
                    .if( gViewCheck ) { view in view.border( .blue )}
                    
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
                                .focusable(false) // Disable blue focusRing
                                .focused($focusedRowIndex, equals: index)
                                .onTapGesture { focusedRowIndex = index }
                                .onMoveCommand { direction in
                                    switch direction {
                                    case .up:
                                        if let current = focusedRowIndex, current > 0 {
                                            let newIndex = current - 1
                                            focusedRowIndex = newIndex
                                            lastClickedRowIndex = newIndex
                                            DispatchQueue.main.async {
                                                selectedTransactionIDs = [filteredTransactionRows[newIndex].id]
                                            }
                                        }
                                    case .down:
                                        if let current = focusedRowIndex,
                                           current < filteredTransactionRows.count - 1 {
                                            let newIndex = current + 1
                                            focusedRowIndex = newIndex
                                            lastClickedRowIndex = newIndex
                                            DispatchQueue.main.async {
                                                selectedTransactionIDs = [filteredTransactionRows[newIndex].id]
                                            }
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
                .if(gViewCheck) { view in view.border(.red).padding(.leading, 0) }
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
        }
        #else
        // iOS version using standard SwiftUI Table
        Table(filteredTransactionRows, selection: $selectedTransactionIDs) {
            TableColumn("Transaction") { row in
                tableCell(row.iOSRowForDisplay, for: row)
                    .onTapGesture {
                        safeUIUpdate {
                            selectedTransactionIDs = [row.id]
                            appState.selectedTransactionID = row.id
                        }
                    }
            }
        }
        .font(.custom("SF Mono Medium", size: 15))
        .frame(minHeight: 300)
        .tableStyle(.inset)
        .contextMenu { SortContextMenu() }
        #endif
    }
    
    // MARK: --- UpdateScaledWidths
#if os(macOS)
    private func updateScaledWidths(for availableWidth: CGFloat) {
        let minWidth: CGFloat = 60
        let totalRequested = columnWidths.values.reduce(0, +)

        // Scale to fit availableWidth proportionally
        // 16 is to not entirely fill available space
        let scaleFactor = (availableWidth - 50) / totalRequested
        scaledColumnWidths = columnWidths.mapValues { max(minWidth, $0 * scaleFactor) }

        // Debug
        print("Scaled column widths: \(scaledColumnWidths)")
    }
#endif



    // MARK: --- ResizeColumn
#if os(macOS)
    private func resizeColumn(title: String, delta: CGFloat) {
        guard let currentWidth = columnWidths[title], availableWidth > 0 else { return }

        let minWidth: CGFloat = 60
        let newWidth = max(minWidth, currentWidth + delta)
        columnWidths[title] = newWidth

        // Total width after resize
        let totalWidth = columnWidths.values.reduce(0, +)

        // If total exceeds availableWidth, shrink flexible columns
        if totalWidth > availableWidth {
            var remainingExcess = totalWidth - availableWidth

            // Flexible columns excluding the dragged one
            let flexibleColumns = columnWidths.keys.filter { $0 != title }

            for key in flexibleColumns.reversed() { // shrink from right
                guard let width = columnWidths[key] else { continue }
                let shrinkable = max(width - minWidth, 0)
                if shrinkable >= remainingExcess {
                    columnWidths[key] = width - remainingExcess
                    remainingExcess = 0
                    break
                } else {
                    columnWidths[key] = width - shrinkable
                    remainingExcess -= shrinkable
                }
            }

            // Clamp dragged column if still over
            if remainingExcess > 0 {
                columnWidths[title] = max(minWidth, newWidth - remainingExcess)
            }
        }

        scaledColumnWidths = columnWidths
        // Save
        UserDefaults.standard.set(columnWidths.mapValues { Double($0) }, forKey: columnWidthsKey)
    }
    #endif

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
        ZStack {                                     // Wrap so background can fill full width
            rowBackground(for: index, row: row)
            HStack(spacing: 0) {
                tableCell(row.paymentMethod, for: row)
                    .frame(width: scaledColumnWidths["Payment Method"] ?? 80)
                    .if( gViewCheck ) { view in view.border( .yellow )}
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
        }
        .if( gViewCheck ) { view in view.border( .green )}
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
                .frame(width: (scaledColumnWidths[title] ?? width) - handleWidth, height: macOSRowHeight, alignment: .leading)
//                .background(Color.gray.opacity(0.1))
//                .border(Color.gray.opacity(0.3), width: 0.5)
            
            // --- Drag handle
            Rectangle()
                .foregroundColor(.white)
                .frame(width: handleWidth, height: macOSRowHeight)
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
        .frame(width: scaledColumnWidths[title] ?? width, height: macOSRowHeight)
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
            // MARK: --- Frint Menu
            ToolbarItem(placement: .automatic) {
                Button {
                    printTransactions()
                } label: {
                    Label("Print Transactions", systemImage: "printer")
                }
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
#if os(macOS)
        let rowWidth = scaledColumnWidths.values.reduce(0, +)
        if selectedTransactionIDs.contains(row.id) {
            let prevSelected = index > 0 && selectedTransactionIDs.contains(filteredTransactionRows[index-1].id)
            let nextSelected = index < filteredTransactionRows.count-1 && selectedTransactionIDs.contains(filteredTransactionRows[index+1].id)
            if !prevSelected && !nextSelected {
                // Single row selected — round all corners
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.blue)
                    .frame(width: rowWidth, height: macOSRowHeight)
            } else if !prevSelected && nextSelected {
                // Top row of multi-selection — round top corners only
                Color.blue
                    .frame(width: rowWidth, height: macOSRowHeight)
                    .clipShape(RoundedCorner(corners: [.topLeft, .topRight], radius: 8))
            } else if prevSelected && !nextSelected {
                // Bottom row of multi-selection — round bottom corners only
                Color.blue
                    .frame(width: rowWidth, height: macOSRowHeight)
                    .clipShape(RoundedCorner(corners: [.bottomLeft, .bottomRight], radius: 8))
            } else {
                // Middle row of multi-selection — no rounding
                Color.blue
                    .frame(width: rowWidth, height: macOSRowHeight)
            }
        } else if index % 2 == 0 {
            Color.clear
                .frame(width: rowWidth, height: macOSRowHeight)
        } else {
            Color.gray.opacity(0.05)
                .frame(width: rowWidth, height: macOSRowHeight)
            
        }
#else
        // TODO: Set to frame width
        let rowWidth:CGFloat = 0 // Not actuallty needed at the moment
        let iOSRowHeight: CGFloat = 40
        if index % 2 == 0 {
            Color.clear
                .frame(height: iOSRowHeight)
                .frame(maxWidth: .infinity) // fill the whole width
        } else {
            Color.gray.opacity(0.05)
                .frame(height: iOSRowHeight)
                .frame(maxWidth: .infinity) // fill the whole width
        }
#endif
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
 
// MARK: --- PrintTransactions
extension BrowseTransactionsView {
    
    func printTransactions() {
        
//        var showCurrencySymbol: Bool { }
        
        let columnWidths: [String: Int] = [
            "Date":          10,
            "Category":      15,
            "Amount":        12,
            "FX":            6,
            "Split":         12,
            "SplitCategory": 15,
            "Payee":         15
        ]
        
        func padded(_ string: String, column: String, alignRight: Bool = false, spacing: Int = 1) -> String {
            guard let width = columnWidths[column] else { return string }
            let actualWidth = max(width, string.count)
            let padding = String(repeating: " ", count: actualWidth - string.count)
            let space = String(repeating: " ", count: spacing)
            return alignRight ? padding + string + space : string + padding + space
        }
        
//        func padded(_ string: String, column: String, alignRight: Bool = false) -> String {
//            guard let width = columnWidths[column] else { return string }
//            if string.count >= width { return String(string.prefix(width)) }
//            let padding = String(repeating: " ", count: width - string.count)
//            return alignRight ? padding + string : string + padding
//        }
        
        let printer = Printer.shared
        let report = NSMutableString()
        
        // MARK: --- Build the report header
        report.append("Full Transactions Report\n")
        report.append(String(repeating: "=", count: 50) + "\n\n")
        report.append(
            padded("Date", column: "Date") +
            padded("Category", column: "Category") +
            padded("Amount", column: "Amount", alignRight: true) +
            padded("FX", column: "FX") +
            padded("Split", column: "Split") +
            padded("Split Category", column: "SplitCategory") +
            padded("Payee", column: "Payee") +
            "\n"
        )
        report.append(String(repeating: "-", count: columnWidths.values.reduce(0, +)) + "\n")
        
        // MARK: --- Add transactions
        for tx in transactions {
            let dateStr     = tx.transactionDate?.formatted(date: .numeric, time: .omitted) ?? ""
            let categoryStr = tx.category.description
            let amountStr   = tx.txAmountAsString( withSymbol: true ) ?? ""
            let fxStr       = tx.currency != .GBP ? (tx.exchangeRateAsString() ?? "") : ""
            let splitStr    = tx.splitAmount != 0 ?  tx.splitAmountAsString( withSymbol: true ) : ""
            let splitCatStr = tx.splitAmount != 0 ?  tx.splitCategory.description : ""
            let payeeStr    = String((tx.payee ?? "" ).prefix(15))
//            let amountStr   = String(format: "%.2f", NSDecimalNumber(decimal: tx.txAmount).doubleValue)
//            let fxStr       = String(format: "%.2f", NSDecimalNumber(decimal: tx.exchangeRate).doubleValue)


            report.append(
                padded(dateStr, column: "Date") +
                padded(categoryStr, column: "Category") +
                padded(amountStr, column: "Amount", alignRight: true) +
                padded(fxStr, column: "FX") +
                padded(splitStr, column: "Split") +
                padded(splitCatStr,column: "SplitCategory") +
                padded(payeeStr, column: "Payee") +
                "\n"
            )
        }
        
        // MARK: --- Create attributes for monospaced font
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        ]
        let attributedReport = NSAttributedString(string: report as String, attributes: attrs)
        
        // MARK: --- Print
        do {
            try printer.printAttributedString(
                attributedReport,
                config: Printer.PageConfiguration(
                    pageSize: CGSize(width: 595, height: 842),
                    pageMargins: Printer.PageMargins(top: 36, left: 36, bottom: 36, right: 36)
                )
            )
        } catch {
            print("Failed to print: \(error)")
        }
    }
    
    func printTransactionsOld() {
        #if os(macOS)
        DispatchQueue.main.async {
            // Build report
            let report = NSMutableString()
            
            // Push content to top of page
            let currentLineCount = report.components(separatedBy: "\n").count
            let totalLinesPerPage = 55 // tweak based on font & page size
            let linesToAdd = max(0, totalLinesPerPage - currentLineCount)
            for _ in 0..<linesToAdd {
                report.append("\n")
            }

            // Create NSTextView
            let printInfo = NSPrintInfo.shared
            let pageSize = printInfo.paperSize
            let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: pageSize.width, height: pageSize.height))
            textView.string = report as String
            textView.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
            textView.isEditable = false
            textView.textContainerInset = .zero // remove any padding

            // Resize to fit content
            if let layoutManager = textView.layoutManager,
               let textContainer = textView.textContainer {
                textContainer.widthTracksTextView = true
                textContainer.heightTracksTextView = false
//                let usedHeight = layoutManager.usedRect(for: textContainer).height
//                textView.frame.size.height = usedHeight
            }

            // Print operation tied to main window
            if let window = NSApp.mainWindow {
                let printOp = NSPrintOperation(view: textView)
                printOp.showsPrintPanel = true
                printOp.showsProgressPanel = true
                printOp.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
            }
        }
        #endif
    }

    
    
//    func printTransactions() {
//        #if os(macOS)
//        DispatchQueue.main.async {
//            // Create the mutable report string (same as CategoriesSummaryView)
//            let report = NSMutableString()
//            report.append("Transactions Report\n")
//            report.append("-----------------------------\n")
//            report.append("Hello World\n")
//            report.append("-----------------------------\n")
//            
//            // Create text view for printing
//            let pageSize = NSMakeSize(595, 842) // A4 at 72dpi
//            let textView = NSTextView(frame: NSRect(origin: .zero, size: pageSize))
//            textView.string = report as String
//            textView.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
//            textView.isEditable = false
//
//            // Keep layout tight to one page
//            if let textContainer = textView.textContainer {
//                textContainer.containerSize = pageSize
//                textContainer.widthTracksTextView = true
//                textContainer.heightTracksTextView = false
//                textContainer.lineFragmentPadding = 0
//            }
//            textView.textContainerInset = .zero
////            let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 595, height: 700))
////            textView.string = report as String
////            textView.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
////            textView.isEditable = false
////            textView.sizeToFit()
//            textView.isHorizontallyResizable = false
//            textView.isVerticallyResizable = true
//            
//            // Print operation (modal, same style as CategoriesSummaryView)
//            let printOp = NSPrintOperation(view: textView)
//            printOp.showsPrintPanel = true
//            printOp.showsProgressPanel = true
//            printOp.runModal(for: NSApp.mainWindow!, delegate: nil, didRun: nil, contextInfo: nil)
//        }
//        #endif
//    }
}

