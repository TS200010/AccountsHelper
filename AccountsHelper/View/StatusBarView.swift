//
//  StatusBarView.swift
// From SkeletonMacOSApp
//
//  Created by Anthony Stanners on 08/09/2025.
//

import SwiftUI
import ItMkLibrary

// MARK: --- StatusBar View
struct StatusBarView: View {
    
    var status: String
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: true)],
        animation: .default
    )
    private var transactions: FetchedResults<Transaction>
    
    // MARK: --- Body
    var body: some View {
        HStack {
            Text("Total Transactions: \(transactions.count)")
                .padding(8)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(status)
        }
        .frame(maxWidth: .infinity, minHeight: 30, maxHeight: 30)
        .topBorder()
        .background(Color("PaleYellow", bundle: .ItMkLibrary))
    }
}
