import Foundation

enum ClearanceSettings {
    static let incomeKey = "income"
    static let baselineWorkDaysKey = "baselineWorkDays"
    static let rentKey = "rent"
    static let targetMizrahiKey = "targetMizrahi"
    static let target1824Key = "target1824"
    static let targetIITKey = "targetIIT"
    static let targetEmergencyFundKey = "targetEmergencyFund"
    static let targetAbarthFundKey = "targetAbarthFund"
    static let targetHobbyFundKey = "targetHobbyFund"
    static let iitTransferNameKey = "iitTransferName"
    static let emergencyFundNameKey = "emergencyFundName"
    static let abarthFundNameKey = "abarthFundName"
    static let hobbyFundNameKey = "hobbyFundName"
    static let iitAnnualRateKey = "iitAnnualRate"
    static let kerenAnnualRateKey = "kerenAnnualRate"

    static let defaultIncome = 10_000.0
    static let defaultBaselineWorkDays = 22.0
    static let defaultRent = 1_300.0
    static let defaultTargetMizrahi = 3_544.0
    static let defaultTarget1824 = 3_250.0
    static let defaultTargetIIT = 1_506.0
    static let defaultTargetEmergencyFund = 1_000.0
    static let defaultTargetAbarthFund = 400.0
    static let defaultTargetHobbyFund = 300.0
    static let defaultIITTransferName = "IIT portfolio"
    static let defaultEmergencyFundName = "Emergency Keren Kaspit"
    static let defaultAbarthFundName = "Abarth Keren Kaspit"
    static let defaultHobbyFundName = "Hobby Keren Kaspit"
    static let defaultIITAnnualRate = 0.08
    static let defaultKerenAnnualRate = 0.0375
}
