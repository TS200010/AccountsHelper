//
//  DebitCredit.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 14/09/2025.
//

import Foundation
import ItMkLibrary

@objc enum DebitCredit: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible, Identifiable {
    
    // MARK: --- Cases
    case DR        = 1
    case CR        = 2
    case unknown   = 99
    
    // MARK: --- Identifiable
    var id: Int32 { self.rawValue }
    
    // MARK: --- Raw Value Helper
    func rawValueAsString() -> String {
        switch self {
        case .DR:      return "DR"
        case .CR:      return "CR"
        case .unknown: return "Unknown"
        }
    }
    
    // MARK: --- CustomStringConvertible
    var description: String {
        switch self {
        case .DR:      return String(localized: "DR")
        case .CR:      return String(localized: "CR")
        case .unknown: return String(localized: "Unknown")
        }
    }
    
    // MARK: --- Conversion Helpers
    static func fromInt(_ i: Int) -> DebitCredit {
        switch i {
        case 1: return .DR
        case 2: return .CR
        default: return .unknown
        }
    }
    
    static func fromInt32(_ i: Int32) -> DebitCredit {
        return DebitCredit.fromInt(Int(i))
    }
}
