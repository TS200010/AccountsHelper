//
//  ReportSpool.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 15/02/2026.
//

import Foundation

final class ReportSpool {

    static let shared = ReportSpool()

    private var reports: [String] = []
    private let pageBreak = "\u{0C}"

    private init() {}
}

extension ReportSpool {

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
extension ReportSpool {

    func print() {
        guard !reports.isEmpty else { return }
        let content = NSMutableString( string: reports.joined(separator: pageBreak) )
        printReport(content)
    }
}
#endif

