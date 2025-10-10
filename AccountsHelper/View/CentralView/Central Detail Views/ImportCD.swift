//
//  ImportCD.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 08/10/2025.
//

import Foundation
import SwiftUI

struct ImportCD: View {
    
    // MARK: --- Local State
    @State private var showConfirmImport = false
    @State private var isCopying = false
    
    // MARK: --- Body
    var body: some View {
        VStack(spacing: 20) {
            Text("Import Transactions")
                .font(.headline)
                .padding(.top, 40)
            
            Text("This will Import all Transactions. Are you sure you want to proceed?")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showConfirmImport = true
            } label: {
                Label("Import Transactions", systemImage: "square.and.arrow.down")
                    .font(.title3)
            }
            .disabled(isCopying)
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .confirmationDialog(
            "Confirm Import",
            isPresented: $showConfirmImport,
            titleVisibility: .visible
        ) {
            Button("Copy Now", role: .destructive) {
                isCopying = true
                DispatchQueue.global(qos: .userInitiated).async {
                    _ = PersistenceController.shared.importTransactionsFromCSV()
                    DispatchQueue.main.async {
                        isCopying = false
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}
