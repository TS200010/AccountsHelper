//
//  ReconcilableAccounts.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 29/09/2024.
//

import Foundation
import ItMkLibrary

@objc enum ReconcilableAccounts: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible, Identifiable {

    // MARK: --- Cases
    case CashGBP    = 1
    case CashUSD    = 2
    case CashEUR    = 3
    case CashYEN    = 4
    case AMEX       = 5
    case VISA       = 6
    case BofSPV     = 7
    case BofSCA     = 8
    case BofSC      = 9
    case BofSIASA   = 10
    case BofSISS    = 11
    case BofSVP     = 12
    case ItMkEquity = 13
    case unknown    = 99

    // MARK: --- Identifiable
    var id: Int32 { self.rawValue }

    // MARK: --- Raw Value Helper
    func rawValueAsString() -> String {
        return self.rawValue.description
    }

    // MARK: --- Currency of PaymentMethod
    var currency: Currency {
        switch self {
        case .CashGBP:    return .GBP
        case .CashUSD:    return .USD
        case .CashEUR:    return .EUR
        case .CashYEN:    return .JPY
        case .AMEX:       return .GBP
        case .VISA:       return .GBP
        case .BofSPV:     return .GBP
        case .BofSCA:     return .GBP
        case .BofSC:      return .GBP
        case .BofSIASA:   return .GBP
        case .BofSISS:    return .GBP
        case .BofSVP:     return .GBP
        case .ItMkEquity: return .GBP
        case .unknown:    return .unknown
        }
    }

    // MARK: --- Human-readable Description
    var description: String {
        switch self {
        case .CashGBP:    return String(localized: "Cash GBP")
        case .CashUSD:    return String(localized: "Cash USD")
        case .CashEUR:    return String(localized: "Cash EUR")
        case .CashYEN:    return String(localized: "Cash YEN")
        case .AMEX:       return String(localized: "AMEX")
        case .VISA:       return String(localized: "VISA")
        case .BofSPV:     return String(localized: "BofS PV")
        case .BofSCA:     return String(localized: "BofS CA")
        case .BofSC:      return String(localized: "BofS C")
        case .BofSIASA:   return String(localized: "BofS IASA")
        case .BofSISS:    return String(localized: "BofS ISS")
        case .BofSVP:     return String(localized: "BofS VP")
        case .ItMkEquity: return String(localized: "ItMk Equity")
        case .unknown:    return String(localized: "Unknown")
        }
    }

    // MARK: --- Code for Reconciliation
    var code: String {
        switch self {
        case .CashGBP:    return "CASH_GBP"
        case .CashUSD:    return "CASH_USD"
        case .CashEUR:    return "CASH_EUR"
        case .CashYEN:    return "CASH_YEN"
        case .AMEX:       return "AMEX"
        case .VISA:       return "VISA"
        case .BofSPV:     return "BOFS_PV"
        case .BofSCA:     return "BOFS_CA"
        case .BofSC:      return "BOFS_C"
        case .BofSIASA:   return "BOFS_IASA"
        case .BofSISS:    return "BOFS_ISS"
        case .BofSVP:     return "BOFS_VP"
        case .ItMkEquity: return "ITMK_EQUITY"
        case .unknown:    return "UNKNOWN"
        }
    }

    // MARK: --- Int Conversion Helpers
    static func fromInt(_ i: Int) -> ReconcilableAccounts {
        switch i {
        case 1:          return .CashGBP
        case 2:          return .CashUSD
        case 3:          return .CashEUR
        case 4:          return .CashYEN
        case 5:          return .AMEX
        case 6:          return .VISA
        case 7:          return .BofSPV
        case 8:          return .BofSCA
        case 9:          return .BofSC
        case 10:         return .BofSIASA
        case 11:         return .BofSISS
        case 12:         return .BofSVP
        case 13:         return .ItMkEquity
        case 99:         return .unknown
        default:         return .unknown
        }
    }

    // MARK: --- FromInt32
    static func fromInt32(_ i: Int32) -> ReconcilableAccounts {
        return ReconcilableAccounts.fromInt(Int(i))
    }
    
    // MARK: --- CurrencyCODE
    var currencyCode: String {
        switch self {
        case .CashGBP:    return "GBP"
        case .CashUSD:    return "USD"
        case .CashEUR:    return "EUR"
        case .CashYEN:    return "YEN"
        case .AMEX:       return "GBP"
        case .VISA:       return "GBP"
        case .BofSPV:     return "GBP"
        case .BofSCA:     return "GBP"
        case .unknown:    return "GBP"
        case .BofSC:      return "GBP"
        case .BofSIASA:   return "GBP"
        case .BofSISS:    return "GBP"
        case .BofSVP:     return "GBP"
        case .ItMkEquity: return "GBP"
        }
    }
}
