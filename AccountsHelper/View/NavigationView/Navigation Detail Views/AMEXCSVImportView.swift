//
//  AMEXCSVImportView.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 21/09/2025.
//

#if os(macOS)
import SwiftUI
import CoreData
import AppKit


struct CSVImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("AMEX CSV Importer")
                .font(.title)
                .padding()

            Button("Select CSV File") {
                selectCSVFile()
            }
            .padding()
        }
        .frame(width: 400, height: 200)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("CSV Import"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func selectCSVFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["csv"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Select an AMEX CSV file to import"

        if panel.runModal() == .OK, let url = panel.url {
            importCSV(at: url)
        }
    }

    private func importCSV(at url: URL) {
        do {
            AMEXCSVImporter.importCSVToCoreData(fileURL: url, context: viewContext)
            alertMessage = "CSV import completed successfully!"
        } catch {
            alertMessage = "Failed to import CSV: \(error.localizedDescription)"
        }
        showingAlert = true
    }
}

#endif

