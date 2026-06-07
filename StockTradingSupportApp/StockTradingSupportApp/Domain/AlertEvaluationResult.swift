//
//  AlertEvaluationResult.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

enum AlertEvaluationResult: Equatable {
    case matched(observedValue: Double)
    case notMatched(observedValue: Double)
    case unavailable(reason: String)
    case disabled

    var displayName: String {
        switch self {
        case .matched:
            return "条件に一致"
        case .notMatched:
            return "条件未一致"
        case .unavailable:
            return "評価できません"
        case .disabled:
            return "無効"
        }
    }

    var detailText: String {
        switch self {
        case .matched:
            return "ユーザー設定条件に一致しました。"
        case .notMatched:
            return "ユーザー設定条件には一致していません。"
        case .unavailable(let reason):
            return reason
        case .disabled:
            return "この条件は無効です。"
        }
    }

    var observedValue: Double? {
        switch self {
        case .matched(let observedValue), .notMatched(let observedValue):
            return observedValue
        case .unavailable, .disabled:
            return nil
        }
    }
}
