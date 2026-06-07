//
//  AlertRuleEvaluator.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct AlertRuleEvaluator {
    private let equalityTolerance: Double

    init(equalityTolerance: Double = 0.0001) {
        self.equalityTolerance = equalityTolerance
    }

    func evaluate(rule: AlertRule, snapshot: StockSnapshot) -> AlertEvaluationResult {
        guard rule.isEnabled else {
            return .disabled
        }

        guard let observedValue = snapshot.value(for: rule.metric) else {
            return .unavailable(reason: "\(rule.metric.displayName)の評価用データがありません。")
        }

        let thresholdValue = rule.thresholdValue
        let isMatched: Bool

        switch rule.comparisonOperator {
        case .greaterThan:
            isMatched = observedValue > thresholdValue
        case .greaterThanOrEqual:
            isMatched = observedValue >= thresholdValue
        case .lessThan:
            isMatched = observedValue < thresholdValue
        case .lessThanOrEqual:
            isMatched = observedValue <= thresholdValue
        case .equal:
            isMatched = abs(observedValue - thresholdValue) <= equalityTolerance
        case .notEqual:
            isMatched = abs(observedValue - thresholdValue) > equalityTolerance
        }

        return isMatched ? .matched(observedValue: observedValue) : .notMatched(observedValue: observedValue)
    }
}
