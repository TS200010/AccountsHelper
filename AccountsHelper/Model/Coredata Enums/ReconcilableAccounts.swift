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
    case CashUKL    = 1
    case CashUSD    = 2
    case CashEUR    = 3
    case CashYEN    = 4
    case AMEX       = 5
    case VISA       = 6
    case BofSPV_82     = 7
    case BofSCA_64     = 8
    case LloydsC_68    = 9
    case BofSIASA_62   = 10
    case BofSISS_43    = 11
    case BofSYP_06     = 12
    case ItMkEquity = 13
    case TMB        = 14
    case unknown    = 99

    // MARK: --- Identifiable
    var id: Int32 { self.rawValue }

    // MARK: --- Raw Value Helper
    func rawValueAsString() -> String {
        return self.rawValue.description
    }

    // MARK: --- Currency of Account
    var currency: Currency {
        switch self {
        case .CashUKL:       return .UKL
        case .CashUSD:       return .USD
        case .CashEUR:       return .EUR
        case .CashYEN:       return .JPY
        case .AMEX:          return .UKL
        case .VISA:          return .UKL
        case .BofSPV_82:     return .UKL
        case .BofSCA_64:     return .UKL
        case .LloydsC_68:    return .UKL
        case .BofSIASA_62:   return .UKL
        case .BofSISS_43:    return .UKL
        case .BofSYP_06:     return .UKL
        case .ItMkEquity:    return .UKL
        case .TMB:           return .JPY
        case .unknown:       return .unknown
        }
    }

    // MARK: --- Human-readable Description
    var description: String {
        switch self {
        case .CashUKL:       return String(localized: "Cash UKL")
        case .CashUSD:       return String(localized: "Cash USD")
        case .CashEUR:       return String(localized: "Cash EUR")
        case .CashYEN:       return String(localized: "Cash YEN")
        case .AMEX:          return String(localized: "AMEX")
        case .VISA:          return String(localized: "VISA")
        case .BofSPV_82:     return String(localized: "BofS PV 82")
        case .BofSCA_64:     return String(localized: "BofS CA 64")
        case .LloydsC_68:    return String(localized: "Lloyds C 68")
        case .BofSIASA_62:   return String(localized: "BofS IASA 62")
        case .BofSISS_43:    return String(localized: "BofS ISS 43")
        case .BofSYP_06:     return String(localized: "BofS YP 06")
        case .ItMkEquity:    return String(localized: "ItMk Equity")
        case .TMB:           return String(localized: "TMB")
        case .unknown:       return String(localized: "Unknown")   // Do not change this string or Reporting will break!
        }
    }

    // MARK: --- Code for Reconciliation
    var code: String {
        switch self {
        case .CashUKL:       return "CASH_UKL"
        case .CashUSD:       return "CASH_USD"
        case .CashEUR:       return "CASH_EUR"
        case .CashYEN:       return "CASH_YEN"
        case .AMEX:          return "AMEX"
        case .VISA:          return "VISA"
        case .BofSPV_82:     return "BOFS_PV_82"
        case .BofSCA_64:     return "BOFS_CA_64"
        case .LloydsC_68:    return "LLOYDS_C_68"
        case .BofSIASA_62:   return "BOFS_IASA_62"
        case .BofSISS_43:    return "BOFS_ISS_56"
        case .BofSYP_06:     return "BOFS_YP_57"
        case .ItMkEquity:    return "ITMK_EQUITY"
        case .TMB:           return "TMB"
        case .unknown:       return "UNKNOWN"
        }
    }
    
    // MARK: --- Pair Codes
    var pairCode: Category{
        switch self {
        case .CashUKL:       return .ToCashUKL
        case .CashUSD:       return .ToCashUSD
        case .CashEUR:       return .ToCashEUR
        case .CashYEN:       return .ToCashYEN
        case .AMEX:          return .AMEXPayment
        case .VISA:          return .VisaPayment
        case .BofSPV_82:     return .ToBofSPV_82
        case .BofSCA_64:     return .ToBofSCA_64
        case .LloydsC_68:    return .ToLloydsC_68
        case .BofSIASA_62:   return .ToBofSIASA_62
        case .BofSISS_43:    return .ToBofSISS_43
        case .BofSYP_06:     return .ToBofSYP_06
        case .ItMkEquity:    return .ToItMkEquity
        case .TMB:           return .ToTMB
        case .unknown:       return .unknown
        }
    }

    // MARK: --- Int Conversion Helpers
    static func fromInt(_ i: Int) -> ReconcilableAccounts {
        switch i {
        case 1:              return .CashUKL
        case 2:              return .CashUSD
        case 3:              return .CashEUR
        case 4:              return .CashYEN
        case 5:              return .AMEX
        case 6:              return .VISA
        case 7:              return .BofSPV_82
        case 8:              return .BofSCA_64
        case 9:              return .LloydsC_68
        case 10:             return .BofSIASA_62
        case 11:             return .BofSISS_43
        case 12:             return .BofSYP_06
        case 13:             return .ItMkEquity
        case 14:             return .TMB
        case 99:             return .unknown
        default:             return .unknown
        }
    }

    // MARK: --- FromInt32
    static func fromInt32(_ i: Int32) -> ReconcilableAccounts {
        return ReconcilableAccounts.fromInt(Int(i))
    }
    
    // MARK: --- CurrencyCODE
    var currencyCode: String {
        switch self {
        case .CashUKL:        return "UKL"
        case .CashUSD:        return "USD"
        case .CashEUR:        return "EUR"
        case .CashYEN:        return "YEN"
        case .AMEX:           return "UKL"
        case .VISA:           return "UKL"
        case .BofSPV_82:      return "UKL"
        case .BofSCA_64:      return "UKL"
        case .LloydsC_68:     return "UKL"
        case .BofSIASA_62:    return "UKL"
        case .BofSISS_43:     return "UKL"
        case .BofSYP_06:      return "UKL"
        case .ItMkEquity:     return "UKL"
        case .TMB:            return "YEN"
        case .unknown:        return "UKL"
        }
    }
    
    // MARK: --- CSV Import
    var accountNumber: String {
        switch self {
        case .BofSPV_82:   return "00142182"
        case .BofSCA_64:   return "10077364"
        case .LloydsC_68:  return "30007768"
        case .BofSIASA_62: return "01511762"
        case .BofSISS_43:  return "01401443"
        case .BofSYP_06:   return "01931306"
        default: return ""
        }
    }
    
    static func fromAccountNumber(_ value: String) -> ReconcilableAccounts? {
        let normalised = value
            .trimmingCharacters(in: .whitespaces)
            .filter(\.isNumber)

        return Self.allCases.first {
            $0.accountNumber == normalised
        }
    }
}
