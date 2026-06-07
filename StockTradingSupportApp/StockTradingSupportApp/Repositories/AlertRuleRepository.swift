//
//  AlertRuleRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

protocol AlertRuleRepository: AnyObject {
    func fetchRules(stockCode: String) -> [AlertRule]
    @discardableResult func add(_ rule: AlertRule) throws -> AlertRule
    @discardableResult func update(_ rule: AlertRule) throws -> AlertRule
    @discardableResult func delete(id: AlertRule.ID) -> Bool
}

enum AlertRuleRepositoryError: Error, Equatable {
    case ruleNotFound(UUID)
}

final class InMemoryAlertRuleRepository: AlertRuleRepository {
    private var rules: [AlertRule]

    init(initialRules: [AlertRule] = []) {
        self.rules = initialRules
    }

    func fetchRules(stockCode: String) -> [AlertRule] {
        rules
            .filter { $0.stockCode == stockCode }
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.createdAt > rhs.createdAt
                }

                return lhs.updatedAt > rhs.updatedAt
            }
    }

    @discardableResult
    func add(_ rule: AlertRule) throws -> AlertRule {
        rules.append(rule)
        return rule
    }

    @discardableResult
    func update(_ rule: AlertRule) throws -> AlertRule {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else {
            throw AlertRuleRepositoryError.ruleNotFound(rule.id)
        }

        rules[index] = rule
        return rule
    }

    @discardableResult
    func delete(id: AlertRule.ID) -> Bool {
        guard let index = rules.firstIndex(where: { $0.id == id }) else {
            return false
        }

        rules.remove(at: index)
        return true
    }
}
