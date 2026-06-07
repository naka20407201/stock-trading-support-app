//
//  AlertEvaluationViewModel.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Combine
import Foundation

struct AlertRuleEvaluationDisplayItem: Identifiable, Equatable {
    var id: AlertRule.ID {
        rule.id
    }

    let rule: AlertRule
    let result: AlertEvaluationResult

    var thresholdText: String {
        rule.metric.formattedValue(rule.thresholdValue)
    }

    var observedValueText: String {
        guard let observedValue = result.observedValue else {
            return "観測値なし"
        }

        return rule.metric.formattedValue(observedValue)
    }

    var conditionText: String {
        "\(rule.metric.displayName) \(rule.comparisonOperator.displayName) \(thresholdText)"
    }
}

final class AlertEvaluationViewModel: ObservableObject {
    let stockCode: String

    @Published private(set) var snapshot: StockSnapshot?
    @Published private(set) var evaluations: [AlertRuleEvaluationDisplayItem] = []
    @Published private(set) var histories: [AlertMatchHistory] = []

    private let alertRuleRepository: any AlertRuleRepository
    private let stockDataProvider: any StockDataProviding
    private let evaluator: AlertRuleEvaluator
    private let historyRepository: any AlertMatchHistoryRepository

    init(
        stockCode: String,
        alertRuleRepository: any AlertRuleRepository,
        stockDataProvider: any StockDataProviding,
        evaluator: AlertRuleEvaluator = AlertRuleEvaluator(),
        historyRepository: any AlertMatchHistoryRepository
    ) {
        self.stockCode = stockCode
        self.alertRuleRepository = alertRuleRepository
        self.stockDataProvider = stockDataProvider
        self.evaluator = evaluator
        self.historyRepository = historyRepository
        refresh()
    }

    func refresh() {
        snapshot = stockDataProvider.snapshot(for: stockCode)
        histories = historyRepository.fetchHistories(stockCode: stockCode)
    }

    func evaluate() {
        let rules = alertRuleRepository.fetchRules(stockCode: stockCode)
        let currentSnapshot = stockDataProvider.snapshot(for: stockCode)
        snapshot = currentSnapshot

        guard let currentSnapshot else {
            evaluations = rules.map { rule in
                AlertRuleEvaluationDisplayItem(
                    rule: rule,
                    result: .unavailable(reason: "評価用データがありません。")
                )
            }
            histories = historyRepository.fetchHistories(stockCode: stockCode)
            return
        }

        evaluations = rules.map { rule in
            let result = evaluator.evaluate(rule: rule, snapshot: currentSnapshot)
            if case .matched(let observedValue) = result {
                addHistoryIfNeeded(
                    rule: rule,
                    observedValue: observedValue,
                    snapshot: currentSnapshot
                )
            }

            return AlertRuleEvaluationDisplayItem(rule: rule, result: result)
        }

        histories = historyRepository.fetchHistories(stockCode: stockCode)
    }

    func clearHistories() {
        historyRepository.deleteAll(stockCode: stockCode)
        histories = []
    }

    private func addHistoryIfNeeded(
        rule: AlertRule,
        observedValue: Double,
        snapshot: StockSnapshot
    ) {
        let existingHistories = historyRepository.fetchHistories(stockCode: stockCode)
        let alreadyExists = existingHistories.contains { history in
            history.alertRuleId == rule.id && history.matchedAt == snapshot.capturedAt
        }

        guard !alreadyExists else {
            return
        }

        let history = AlertMatchHistory(
            stockCode: stockCode,
            alertRuleId: rule.id,
            alertRuleName: rule.name,
            metric: rule.metric,
            comparisonOperator: rule.comparisonOperator,
            thresholdValue: rule.thresholdValue,
            observedValue: observedValue,
            matchedAt: snapshot.capturedAt,
            sourceName: snapshot.sourceName
        )

        _ = try? historyRepository.add(history)
    }
}
