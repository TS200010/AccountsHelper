//
//  ReportSpooler.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 15/02/2026.
//

import Foundation
import PrintingKit
// import AppKit

final class ReportSpooler {

    static let shared = ReportSpooler()

    private var reports: [String] = []
    private let pageBreak = "\u{0C}"

    private init() {}
}

extension ReportSpooler {

//    func append(_ report: String) {
//        guard !report.isEmpty else { return }
//
//        // Convert the string to NSAttributedString with monospaced font
//        let attrs: [NSAttributedString.Key: Any] = [
//            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
//        ]
//
//        let attributedReport = NSAttributedString(string: report, attributes: attrs)
//        reports.append(attributedReport)
//    }
    
    func append(_ report: String) {
        guard !report.isEmpty else { return }
        reports.append(report)
    }

    func clear() {
        reports.removeAll()
    }

    var isEmpty: Bool {
        reports.isEmpty
    }
}

#if os(macOS)
extension ReportSpooler {
    
    func print() {
        guard !reports.isEmpty else { return }
        
        for report in reports {
            let r = NSMutableString(string: report)
            printReport( r )
        }
        
        clear()
    }
}
#endif

