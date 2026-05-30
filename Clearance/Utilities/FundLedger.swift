import Foundation

/// Derives persistent fund balances from the full ledger of contributions (confirmed routing
/// rows) and withdrawals (fund-tagged spend rows) across all months. Balances are always
/// computed live — never stored — so editing any month keeps the math consistent.
struct FundLedger {
    /// Net flow per fund, computed once: Σ confirmed contributions − Σ withdrawals, keyed by
    /// fundID. Looking up a balance is then O(1), so per-row rendering stays cheap even with
    /// many months and categories.
    private let netFlowByFund: [UUID: Double]

    init(contributions: [RoutingCategory], withdrawals: [SpendCategory]) {
        var net: [UUID: Double] = [:]
        for contribution in contributions where contribution.didTransfer {
            if let id = contribution.fundID { net[id, default: 0] += contribution.target }
        }
        for withdrawal in withdrawals {
            if let id = withdrawal.fundID { net[id, default: 0] -= withdrawal.actual }
        }
        netFlowByFund = net
    }

    /// `openingBalance + (Σ confirmed contributions − Σ withdrawals)`, for one fund.
    func balance(of fund: Fund) -> Double {
        fund.openingBalance + (netFlowByFund[fund.id] ?? 0)
    }

    /// Balance available *before* a given withdrawal row counts — used to flag over-withdrawal
    /// (logging more against a fund than it currently holds).
    func availableBefore(_ withdrawal: SpendCategory, of fund: Fund) -> Double {
        let here = withdrawal.fundID == fund.id ? withdrawal.actual : 0
        return balance(of: fund) + here
    }
}
