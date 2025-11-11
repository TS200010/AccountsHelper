//
//  PrintReport.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 10/11/2025.
//

import Foundation
import PrintingKit
import SwiftUI

func printReport(_ report: NSMutableString) {

    #if os(macOS)
    // MARK: --- Create attributes for monospaced font
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
    ]
    let attributedReport = NSAttributedString(string: report as String, attributes: attrs)
    
    // MARK: --- Print
    let printer = Printer.shared
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
    #endif
}
