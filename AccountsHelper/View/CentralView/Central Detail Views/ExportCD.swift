//
//  ExportCD.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 08/10/2025.
//

import Foundation
import SwiftUI

struct ExportCD: View {
    
    // MARK: --- Local State
    @State private var showConfirmExport = false
    @State private var isCopying = false
    
    // MARK: --- Body
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Transactions")
                .font(.headline)
                .padding(.top, 40)
            
            Text("This will Export all transactions. Are you sure you want to proceed?")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showConfirmExport = true
            } label: {
                Label("Export Transactions", systemImage: "square.and.arrow.up")
                    .font(.title3)
            }
            .disabled(isCopying)
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .confirmationDialog(
            "Confirm Export",
            isPresented: $showConfirmExport,
            titleVisibility: .visible
        ) {
            Button("Copy Now", role: .destructive) {
                isCopying = true
                DispatchQueue.global(qos: .userInitiated).async {
                    _ = PersistenceController.shared.exportTransactionsToCSV()
                    DispatchQueue.main.async {
                        isCopying = false
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}
