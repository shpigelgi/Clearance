import Foundation

/// Derives persistent fund balances from the full ledger of contributions (confirmed routing
/// rows) and withdrawals (fund-tagged spend rows) across all months. Balances are always
/// computed live — never stored — so editing any month keeps the math consistent.
struct FundLedger {
    let contributions: [RoutingCategory]
    let withdrawals: [SpendCategory]

    /// `openingBalance + Σ confirmed contributions − Σ withdrawals`, for one fund.
    func balance(of fund: Fund) -> Double {
        let inflow = contributions.reduce(0.0) { sum, c in
            (c.fundID == fund.id && c.didTransfer) ? sum + c.target : sum
        }
        let outflow = withdrawals.reduce(0.0) { sum, w in
            w.fundID == fund.id ? sum + w.actual : sum
        }
        return fund.openingBalance + inflow - outflow
    }

    /// Balance available *before* a given withdrawal row counts — used to flag over-withdrawal
    /// (logging more against a fund than it currently holds).
    func availableBefore(_ withdrawal: SpendCategory, of fund: Fund) -> Double {
        let here = withdrawal.fundID == fund.id ? withdrawal.actual : 0
        return balance(of: fund) + here
    }
}
