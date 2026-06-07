//
//  SwiftDataAlertRuleRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation
import SwiftData

final class SwiftDataAlertRuleRepository: AlertRuleRepository, RepositoryReadStatusProviding {
    // The container is retained to keep in-memory test stores alive for the repository lifetime.
    private let modelContainer: ModelContainer?
    private let modelContext: ModelContext
    private(set) var readErrorMessage: String?

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
            readErrorMessage = nil
            return try fetchRecords(stockCode: stockCode).compactMap(\.domainModel)
        } catch {
            readErrorMessage = RepositoryStatusMessage.readFailed
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
            guard let record = try fetchRecord(id: rule.id) else {
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
            guard let record = try fetchRecord(id: id) else {
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

    private func fetchRecords(stockCode: String) throws -> [AlertRuleRecord] {
        let targetStockCode = stockCode
        let descriptor = FetchDescriptor<AlertRuleRecord>(
            predicate: #Predicate { record in
                record.stockCode == targetStockCode
            },
            sortBy: [
                SortDescriptor(\.updatedAt, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchRecord(id: AlertRule.ID) throws -> AlertRuleRecord? {
        let targetID = id
        var descriptor = FetchDescriptor<AlertRuleRecord>(
            predicate: #Predicate { record in
                record.id == targetID
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
