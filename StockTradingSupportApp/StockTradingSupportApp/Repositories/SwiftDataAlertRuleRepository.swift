//
//  SwiftDataAlertRuleRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation
import SwiftData

final class SwiftDataAlertRuleRepository: AlertRuleRepository {
    // The container is retained to keep in-memory test stores alive for the repository lifetime.
    private let modelContainer: ModelContainer?
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContainer = nil
        self.modelContext = modelContext
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }

    func fetchRules(stockCode: String) -> [AlertRule] {
        do {
            return try fetchRecords()
                .filter { $0.stockCode == stockCode }
                .compactMap(\.domainModel)
                .sorted { lhs, rhs in
                    if lhs.updatedAt == rhs.updatedAt {
                        return lhs.createdAt > rhs.createdAt
                    }

                    return lhs.updatedAt > rhs.updatedAt
                }
        } catch {
            // TODO: Surface persistence read failures through ViewModel state instead of showing an empty list.
            return []
        }
    }

    @discardableResult
    func add(_ rule: AlertRule) throws -> AlertRule {
        let record = AlertRuleRecord(rule: rule)
        modelContext.insert(record)

        do {
            try modelContext.save()
            return rule
        } catch {
            modelContext.rollback()
            throw AlertRuleRepositoryError.persistenceFailure(error.localizedDescription)
        }
    }

    @discardableResult
    func update(_ rule: AlertRule) throws -> AlertRule {
        do {
            guard let record = try fetchRecords().first(where: { $0.id == rule.id }) else {
                throw AlertRuleRepositoryError.ruleNotFound(rule.id)
            }

            record.stockCode = rule.stockCode
            record.name = rule.name
            record.metricRawValue = rule.metric.rawValue
            record.comparisonOperatorRawValue = rule.comparisonOperator.rawValue
            record.thresholdValue = rule.thresholdValue
            record.isEnabled = rule.isEnabled
            record.createdAt = rule.createdAt
            record.updatedAt = rule.updatedAt

            try modelContext.save()
            return rule
        } catch let error as AlertRuleRepositoryError {
            throw error
        } catch {
            modelContext.rollback()
            throw AlertRuleRepositoryError.persistenceFailure(error.localizedDescription)
        }
    }

    @discardableResult
    func delete(id: AlertRule.ID) -> Bool {
        do {
            guard let record = try fetchRecords().first(where: { $0.id == id }) else {
                return false
            }

            modelContext.delete(record)
            try modelContext.save()
            return true
        } catch {
            modelContext.rollback()
            return false
        }
    }

    private func fetchRecords() throws -> [AlertRuleRecord] {
        try modelContext.fetch(FetchDescriptor<AlertRuleRecord>())
    }
}
