//
//  Currency.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 13/09/2025.
//

import Foundation
import ItMkLibrary

@objc enum Currency: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible, Identifiable {

    // MARK: --- Cases
    case GBP      = 1
    case USD      = 2
    case JPY      = 3
    case EUR      = 4
    case unknown  = 99

    // MARK: --- Identifiable
    var id: Int32 { self.rawValue }

    // MARK: --- Initializer from String
    init(_ s: String) {
        self = Currency.fromString(s)
    }

    // MARK: --- Raw Value Helper
    func rawValueAsString() -> String {
        return self.rawValue.description
    }

    // MARK: --- String conversion
    static func fromString(_ s: String) -> Currency {
        switch s {
        case "GBP":             return .GBP
        case "USD":             return .USD
        case "JPY":             return .JPY
        case "JAPANESE YEN":    return .JPY
        case "JAPANESEYEN":     return .JPY
        case "EUR":             return .EUR
        default:                return .unknown
        }
    }

    // MARK: --- Int Conversion Helpers
    static func fromInt(_ i: Int) -> Currency {
        switch i {
        case 1: return .GBP
        case 2: return .USD
        case 3: return .JPY
        case 4: return .EUR
        default: return .unknown
        }
    }

    static func fromInt32(_ i: Int32) -> Currency {
        return Currency.fromInt(Int(i))
    }

    // MARK: --- CustomStringConvertible
    var description: String {
        switch self {
        case .GBP:     return String(localized: "GBP")
        case .USD:     return String(localized: "USD")
        case .JPY:     return String(localized: "JPY")
        case .EUR:     return String(localized: "EUR")
        case .unknown: return String(localized: "Unknown")
        }
    }
}
