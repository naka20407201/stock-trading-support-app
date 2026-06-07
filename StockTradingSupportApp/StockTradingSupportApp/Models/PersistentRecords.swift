//
//  PersistentRecords.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation
import SwiftData

@Model
final class WatchlistItemRecord {
    var id: UUID
    var code: String
    var name: String
    var market: String
    var industry: String
    var isNikkei225: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        code: String,
        name: String,
        market: String,
        industry: String,
        isNikkei225: Bool,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.market = market
        self.industry = industry
        self.isNikkei225 = isNikkei225
        self.createdAt = createdAt
    }

    convenience init(item: WatchlistItem) {
        self.init(
            id: item.id,
            code: item.code,
            name: item.name,
            market: item.market,
            industry: item.industry,
            isNikkei225: item.isNikkei225,
            createdAt: item.createdAt
        )
    }

    var domainModel: WatchlistItem {
        WatchlistItem(record: self)
    }
}

extension WatchlistItem {
    init(record: WatchlistItemRecord) {
        self.init(
            id: record.id,
            code: record.code,
            name: record.name,
            market: record.market,
            industry: record.industry,
            isNikkei225: record.isNikkei225,
            createdAt: record.createdAt
        )
    }
}

@Model
final class InvestmentMemoRecord {
    var id: UUID
    var stockCode: String
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        stockCode: String,
        title: String,
        body: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.stockCode = stockCode
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(memo: InvestmentMemo) {
        self.init(
            id: memo.id,
            stockCode: memo.stockCode,
            title: memo.title,
            body: memo.body,
            createdAt: memo.createdAt,
            updatedAt: memo.updatedAt
        )
    }

    var domainModel: InvestmentMemo {
        InvestmentMemo(record: self)
    }
}

extension InvestmentMemo {
    init(record: InvestmentMemoRecord) {
        self.init(
            id: record.id,
            stockCode: record.stockCode,
            title: record.title,
            body: record.body,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }
}

@Model
final class AlertRuleRecord {
    var id: UUID
    var stockCode: String
    var name: String
    var metricRawValue: String
    var comparisonOperatorRawValue: String
    var thresholdValue: Double
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        stockCode: String,
        name: String,
        metricRawValue: String,
        comparisonOperatorRawValue: String,
        thresholdValue: Double,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.stockCode = stockCode
        self.name = name
        self.metricRawValue = metricRawValue
        self.comparisonOperatorRawValue = comparisonOperatorRawValue
        self.thresholdValue = thresholdValue
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(rule: AlertRule) {
        self.init(
            id: rule.id,
            stockCode: rule.stockCode,
            name: rule.name,
            metricRawValue: rule.metric.rawValue,
            comparisonOperatorRawValue: rule.comparisonOperator.rawValue,
            thresholdValue: rule.thresholdValue,
            isEnabled: rule.isEnabled,
            createdAt: rule.createdAt,
            updatedAt: rule.updatedAt
        )
    }

    var domainModel: AlertRule? {
        AlertRule(record: self)
    }
}

extension AlertRule {
    init?(record: AlertRuleRecord) {
        guard
            let metric = AlertMetric(rawValue: record.metricRawValue),
            let comparisonOperator = ComparisonOperator(rawValue: record.comparisonOperatorRawValue)
        else {
            return nil
        }

        self.init(
            id: record.id,
            stockCode: record.stockCode,
            name: record.name,
            metric: metric,
            comparisonOperator: comparisonOperator,
            thresholdValue: record.thresholdValue,
            isEnabled: record.isEnabled,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }
}

@Model
final class AlertMatchHistoryRecord {
    var id: UUID
    var stockCode: String
    var alertRuleId: UUID
    var alertRuleName: String
    var metricRawValue: String
    var comparisonOperatorRawValue: String
    var thresholdValue: Double
    var observedValue: Double
    var matchedAt: Date
    var sourceName: String

    init(
        id: UUID = UUID(),
        stockCode: String,
        alertRuleId: UUID,
        alertRuleName: String,
        metricRawValue: String,
        comparisonOperatorRawValue: String,
        thresholdValue: Double,
        observedValue: Double,
        matchedAt: Date,
        sourceName: String
    ) {
        self.id = id
        self.stockCode = stockCode
        self.alertRuleId = alertRuleId
        self.alertRuleName = alertRuleName
        self.metricRawValue = metricRawValue
        self.comparisonOperatorRawValue = comparisonOperatorRawValue
        self.thresholdValue = thresholdValue
        self.observedValue = observedValue
        self.matchedAt = matchedAt
        self.sourceName = sourceName
    }

    convenience init(history: AlertMatchHistory) {
        self.init(
            id: history.id,
            stockCode: history.stockCode,
            alertRuleId: history.alertRuleId,
            alertRuleName: history.alertRuleName,
            metricRawValue: history.metric.rawValue,
            comparisonOperatorRawValue: history.comparisonOperator.rawValue,
            thresholdValue: history.thresholdValue,
            observedValue: history.observedValue,
            matchedAt: history.matchedAt,
            sourceName: history.sourceName
        )
    }

    var domainModel: AlertMatchHistory? {
        AlertMatchHistory(record: self)
    }
}

extension AlertMatchHistory {
    init?(record: AlertMatchHistoryRecord) {
        guard
            let metric = AlertMetric(rawValue: record.metricRawValue),
            let comparisonOperator = ComparisonOperator(rawValue: record.comparisonOperatorRawValue)
        else {
            return nil
        }

        self.init(
            id: record.id,
            stockCode: record.stockCode,
            alertRuleId: record.alertRuleId,
            alertRuleName: record.alertRuleName,
            metric: metric,
            comparisonOperator: comparisonOperator,
            thresholdValue: record.thresholdValue,
            observedValue: record.observedValue,
            matchedAt: record.matchedAt,
            sourceName: record.sourceName
        )
    }
}

@Model
final class ManualStockSnapshotInputRecord {
    var id: UUID
    var stockCode: String
    var currentPrice: Double?
    var per: Double?
    var pbr: Double?
    var volume: Double?
    var updatedAt: Date
    var sourceName: String

    init(
        id: UUID = UUID(),
        stockCode: String,
        currentPrice: Double? = nil,
        per: Double? = nil,
        pbr: Double? = nil,
        volume: Double? = nil,
        updatedAt: Date = Date(),
        sourceName: String = "手入力評価データ"
    ) {
        self.id = id
        self.stockCode = stockCode
        self.currentPrice = currentPrice
        self.per = per
        self.pbr = pbr
        self.volume = volume
        self.updatedAt = updatedAt
        self.sourceName = sourceName
    }

    convenience init(input: ManualStockSnapshotInput) {
        self.init(
            id: input.id,
            stockCode: input.stockCode,
            currentPrice: input.currentPrice,
            per: input.per,
            pbr: input.pbr,
            volume: input.volume,
            updatedAt: input.updatedAt,
            sourceName: input.sourceName
        )
    }

    var domainModel: ManualStockSnapshotInput {
        ManualStockSnapshotInput(record: self)
    }
}

extension ManualStockSnapshotInput {
    init(record: ManualStockSnapshotInputRecord) {
        self.init(
            id: record.id,
            stockCode: record.stockCode,
            currentPrice: record.currentPrice,
            per: record.per,
            pbr: record.pbr,
            volume: record.volume,
            updatedAt: record.updatedAt,
            sourceName: record.sourceName
        )
    }
}
