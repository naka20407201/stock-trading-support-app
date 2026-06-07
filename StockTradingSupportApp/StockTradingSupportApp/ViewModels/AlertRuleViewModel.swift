//
//  AlertRuleViewModel.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Combine
import Foundation

final class AlertRuleViewModel: ObservableObject {
    let stockCode: String

    @Published private(set) var rules: [AlertRule] = []

    private let repository: any AlertRuleRepository

    init(
        stockCode: String,
        repository: any AlertRuleRepository
    ) {
        self.stockCode = stockCode
        self.repository = repository
        refresh()
    }

    func refresh() {
        rules = repository.fetchRules(stockCode: stockCode)
    }

    @discardableResult
    func addRule(
        name: String,
        metric: AlertMetric,
        comparisonOperator: ComparisonOperator,
        thresholdValueText: String,
        isEnabled: Bool
    ) throws -> AlertRule {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let thresholdValue = try validate(
            name: normalizedName,
            thresholdValueText: thresholdValueText
        )

        let rule = AlertRule(
            stockCode: stockCode,
            name: normalizedName,
            metric: metric,
            comparisonOperator: comparisonOperator,
            thresholdValue: thresholdValue,
            isEnabled: isEnabled
        )

        let addedRule = try repository.add(rule)
        refresh()
        return addedRule
    }

    @discardableResult
    func updateRule(
        id: AlertRule.ID,
        name: String,
        metric: AlertMetric,
        comparisonOperator: ComparisonOperator,
        thresholdValueText: String,
        isEnabled: Bool
    ) throws -> AlertRule {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let thresholdValue = try validate(
            name: normalizedName,
            thresholdValueText: thresholdValueText
        )

        guard let existingRule = rules.first(where: { $0.id == id }) else {
            throw AlertRuleRepositoryError.ruleNotFound(id)
        }

        let updatedRule = existingRule.updating(
            name: normalizedName,
            metric: metric,
            comparisonOperator: comparisonOperator,
            thresholdValue: thresholdValue,
            isEnabled: isEnabled
        )

        let savedRule = try repository.update(updatedRule)
        refresh()
        return savedRule
    }

    func deleteRule(id: AlertRule.ID) {
        _ = repository.delete(id: id)
        refresh()
    }

    func toggleEnabled(id: AlertRule.ID) {
        guard let existingRule = rules.first(where: { $0.id == id }) else {
            return
        }

        let updatedRule = existingRule.updating(isEnabled: !existingRule.isEnabled)
        _ = try? repository.update(updatedRule)
        refresh()
    }

    private func validate(name: String, thresholdValueText: String) throws -> Double {
        guard !name.isEmpty else {
            throw AlertRuleValidationError.emptyName
        }

        let normalizedThresholdValue = thresholdValueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let thresholdValue = Double(normalizedThresholdValue) else {
            throw AlertRuleValidationError.invalidThreshold
        }

        guard thresholdValue >= 0 else {
            throw AlertRuleValidationError.negativeThreshold
        }

        return thresholdValue
    }
}
