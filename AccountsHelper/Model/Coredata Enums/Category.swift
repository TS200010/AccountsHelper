//
//  Category.swift
//  AccountsHelper
//
//  Created by Anthony Stanners on 14/09/2025.
//

import Foundation
import ItMkLibrary

@objc enum Category: Int32, CaseIterable, Codable, HasStringRepresentation, CustomStringConvertible, Identifiable {

    // MARK: --- Cases
    case YPension           = 1
    case GardenHome         = 2
    case Insurance          = 3
    case CarTax             = 4
    case CarMaintenance     = 5
    case Giving             = 6
    case Maintenance        = 7
    case FoodHousehold      = 8
    case AMWAY              = 9
    case Wine               = 10
    case Entertainments     = 11
    case Travel             = 12
    case TransportPetrol    = 13
    case BooksCDs           = 14
    case Medical            = 15
    case Clothing           = 16
    case CapitalExpenses    = 17
    case CompOfficeAV       = 18
    case Hobbies            = 19
    case Presents           = 20
    case Spare1             = 21
    case MiscOther          = 22
    case InterestCharges    = 23
    case ToBalance          = 24
    case MortgageInterest   = 25
    case Phone              = 26
    case Utilities          = 27
    case CouncilTax         = 28

    case ToYokko            = 50
    case ToAJBell           = 51
    case IntDivIncome       = 52
    case OtherIncome        = 53
    case StatePensionT      = 54
    case StatePensionY      = 55
    case NCRPension         = 56
    case VisaPayment        = 57
    case AMEXPatment        = 58

    case OpeningBalance     = 98
    case unknown            = 999

    // MARK: --- Identifiable
    var id: Int32 { self.rawValue }

    // MARK: --- Raw Value Helper
    func rawValueAsString() -> String {
        return self.rawValue.description
    }

    // MARK: --- CustomStringConvertible
    var description: String {
        switch self {
        case .YPension:         return String(localized: "Y Pension")
        case .GardenHome:       return String(localized: "GardenHome")
        case .Insurance:        return String(localized: "Insurance")
        case .CarTax:           return String(localized: "CarTax")
        case .CarMaintenance:   return String(localized: "CarMaintenance")
        case .Giving:           return String(localized: "Giving")
        case .Maintenance:      return String(localized: "Maintenance")
        case .FoodHousehold:    return String(localized: "FoodHousehold")
        case .AMWAY:            return String(localized: "AMWAY")
        case .Wine:             return String(localized: "Wine")
        case .Entertainments:   return String(localized: "Entertainments")
        case .Travel:           return String(localized: "Travel")
        case .TransportPetrol:  return String(localized: "TransportPetrol")
        case .BooksCDs:         return String(localized: "BooksCDs")
        case .Medical:          return String(localized: "Medical")
        case .Clothing:         return String(localized: "Clothing")
        case .CapitalExpenses:  return String(localized: "CapitalExpenses")
        case .CompOfficeAV:     return String(localized: "OfficeCompAV")
        case .Hobbies:          return String(localized: "Hobbies")
        case .Presents:         return String(localized: "Presents")
        case .Spare1:           return String(localized: "Spare1")
        case .MiscOther:        return String(localized: "MiscOther")
        case .InterestCharges:  return String(localized: "InterestCharges")
        case .ToBalance:        return String(localized: "ToBalance")
        case .MortgageInterest: return String(localized: "MortgageInterest")
        case .Phone:            return String(localized: "Phone")
        case .Utilities:        return String(localized: "Utilities")
        case .CouncilTax:       return String(localized: "CouncilTax")
        case .ToYokko:          return String(localized: "ToYokko")
        case .ToAJBell:         return String(localized: "ToAJBell")
        case .IntDivIncome:     return String(localized: "IntDivIncome")
        case .OtherIncome:      return String(localized: "OtherIncome")
        case .StatePensionT:    return String(localized: "StatePensionT")
        case .StatePensionY:    return String(localized: "StatePensionY")
        case .NCRPension:       return String(localized: "NCRPension")
        case .VisaPayment:      return String(localized: "VisaPayment")
        case .AMEXPatment:      return String(localized: "AMEXPatment")
        case .OpeningBalance:   return String(localized: "OpeningBalance")
        case .unknown:          return String(localized: "Unknown")
        }
    }
}
