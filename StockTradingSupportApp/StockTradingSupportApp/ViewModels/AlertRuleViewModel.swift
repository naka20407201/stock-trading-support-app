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
    @Published private(set) var errorMessage: String?

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
        syncReadError()
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
        let didDelete = repository.delete(id: id)
        refresh()

        if !didDelete && errorMessage == nil {
            errorMessage = RepositoryStatusMessage.deleteFailed
        }
    }

    func toggleEnabled(id: AlertRule.ID) throws {
        guard let existingRule = rules.first(where: { $0.id == id }) else {
            throw AlertRuleRepositoryError.ruleNotFound(id)
        }

        let updatedRule = existingRule.updating(isEnabled: !existingRule.isEnabled)
        do {
            _ = try repository.update(updatedRule)
            refresh()
        } catch {
            refresh()
            errorMessage = "条件の有効状態を更新できませんでした。"
            throw error
        }
    }

    func formattedThresholdValue(for rule: AlertRule) -> String {
        rule.metric.formattedValue(rule.thresholdValue)
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

    private func syncReadError() {
        errorMessage = (repository as? any RepositoryReadStatusProviding)?.readErrorMessage
    }
}
