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
}
