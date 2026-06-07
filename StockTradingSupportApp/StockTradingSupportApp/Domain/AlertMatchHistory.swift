//
//  AlertMatchHistory.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct AlertMatchHistory: Identifiable, Equatable, Hashable {
    let id: UUID
    let stockCode: String
    let alertRuleId: UUID
    let alertRuleName: String
    let metric: AlertMetric
    let comparisonOperator: ComparisonOperator
    let thresholdValue: Double
    let observedValue: Double
    let matchedAt: Date
    let sourceName: String

    init(
        id: UUID = UUID(),
        stockCode: String,
        alertRuleId: UUID,
        alertRuleName: String,
        metric: AlertMetric,
        comparisonOperator: ComparisonOperator,
        thresholdValue: Double,
        observedValue: Double,
        matchedAt: Date,
        sourceName: String
    ) {
        self.id = id
        self.stockCode = stockCode
        self.alertRuleId = alertRuleId
        self.alertRuleName = alertRuleName
        self.metric = metric
        self.comparisonOperator = comparisonOperator
        self.thresholdValue = thresholdValue
        self.observedValue = observedValue
        self.matchedAt = matchedAt
        self.sourceName = sourceName
    }
}
