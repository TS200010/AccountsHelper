//
//  String+Padded.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 11/11/2025.
//

import Foundation

extension String {
    enum Alignment {
        case leading   // spaces go on the right
        case trailing  // spaces go on the left
    }
    
    /// Pads the string to the specified total length with spaces.
    /// - Parameters:
    ///   - length: The total desired length of the resulting string.
    ///   - alignment: `.leading` (default) or `.trailing`
    /// - Returns: A string padded with spaces to the requested length.
    func padded(to length: Int, alignment: Alignment = .leading) -> String {
        let count = self.count
        guard count < length else { return self } // no truncation
        let padding = String(repeating: " ", count: length - count)
        switch alignment {
        case .leading:
            return self + padding
        case .trailing:
            return padding + self
        }
    }
}
