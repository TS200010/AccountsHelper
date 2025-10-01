//
//  PaymentMethod.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 29/09/2024.
//

import Foundation
import ItMkLibrary


@objc enum PaymentMethod: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible {

    case CashGBP        = 1
    case CashUSD        = 2
    case CashEUR        = 3
    case CashYEN        = 4
    case AMEX           = 5
    case VISA           = 6
    case BofSPV         = 7
    case BofSCA         = 8
    case unknown        = 99

    // Initialize from string
//    init(_ s: String) {
//        self = PaymentMethod.fromString(s)
//    }

    // Raw value as string
    func rawValueAsString() -> String {
        return self.rawValue.description
    }
    
    // Currency of the paymentMethod
    var currency: Currency {
        switch self {
        case .CashGBP:        return .GBP
        case .CashUSD:        return .USD
        case .CashEUR:        return .EUR
        case .CashYEN:        return .JPY
        case .AMEX:           return .GBP
        case .VISA:           return .GBP
        case .BofSPV:         return .GBP
        case .BofSCA:         return .GBP
        case .unknown:        return .unknown
        }
    }

    // Human-readable description
    var description: String {
        switch self {
        case .CashGBP:        return String(localized: "Cash GBP")
        case .CashUSD:        return String(localized: "Cash USD")
        case .CashEUR:        return String(localized: "Cash EUR")
        case .CashYEN:        return String(localized: "Cash YEN")
        case .AMEX:           return String(localized: "AMEX")
        case .VISA:           return String(localized: "VISA")
        case .BofSPV:         return String(localized: "BofS PV")
        case .BofSCA:         return String(localized: "BofS CA")
        case .unknown:        return String(localized: "Unknown")
        }
    }
    
    // MARK: --- NOTE: code is used in the periodKey in Reconciliation.
    // ... Changing this such that existing codes change will break reconciliation
    var code: String {
        switch self {
        case .CashGBP: return "CASH_GBP"
        case .CashUSD: return "CASH_USD"
        case .CashEUR: return "CASH_EUR"
        case .CashYEN: return "CASH_YEN"
        case .AMEX:    return "AMEX"
        case .VISA:    return "VISA"
        case .BofSPV:  return "BOFS_PV"
        case .BofSCA:  return "BOFS_CA"
        case .unknown: return "UNKNOWN"
        }
    }

//    // Convert from string
//    static func fromString(_ s: String) -> PaymentMethod {
//        switch s {
//        case "Cash GBP":       return .CashGBP
//        case "Cash USD":       return .CashUSD
//        case "Cash EUR":       return .CashEUR
//        case "Cash YEN":       return .CashYEN
//        case "AMEX":           return .AMEX
//        case "VISA":           return .VISA
//        case "BofS PV":        return .BofSPV
//        default:               return .unknown
//        }
//    }

    // Convert from Int
    static func fromInt(_ i: Int) -> PaymentMethod {
        switch i {
        case 1: return .CashGBP
        case 2: return .CashUSD
        case 3: return .CashEUR
        case 4: return .CashYEN
        case 5: return .AMEX
        case 6: return .VISA
        case 7: return .BofSPV
        default: return .unknown
        }
    }

    // Convert from Int32
    static func fromInt32(_ i: Int32) -> PaymentMethod {
        return PaymentMethod.fromInt(Int(i))
    }
}

