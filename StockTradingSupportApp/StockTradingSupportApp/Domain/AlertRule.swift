//
//  AlertRule.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

enum AlertMetric: String, CaseIterable, Identifiable {
    case currentPrice
    case per
    case pbr
    case volume

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .currentPrice:
            return "現在値"
        case .per:
            return "PER"
        case .pbr:
            return "PBR"
        case .volume:
            return "出来高"
        }
    }

    var unitName: String {
        switch self {
        case .currentPrice:
            return "円"
        case .per, .pbr:
            return "倍"
        case .volume:
            return "株"
        }
    }

    func formattedValue(_ value: Double) -> String {
        switch self {
        case .currentPrice:
            return "\(Int(value.rounded()))円"
        case .per, .pbr:
            return "\(Self.decimalFormatter.string(from: NSNumber(value: value)) ?? String(value))倍"
        case .volume:
            return "\(Int(value.rounded()))株"
        }
    }

    static var selectableCases: [AlertMetric] {
        [.currentPrice, .per, .pbr, .volume]
    }

    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

enum ComparisonOperator: String, CaseIterable, Identifiable {
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual
    case equal
    case notEqual

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .greaterThan:
            return "より大きい"
        case .greaterThanOrEqual:
            return "以上"
        case .lessThan:
            return "より小さい"
        case .lessThanOrEqual:
            return "以下"
        case .equal:
            return "等しい"
        case .notEqual:
            return "等しくない"
        }
    }
}

struct AlertRule: Identifiable, Equatable, Hashable {
    let id: UUID
    let stockCode: String
    let name: String
    let metric: AlertMetric
    let comparisonOperator: ComparisonOperator
    let thresholdValue: Double
    let isEnabled: Bool
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        stockCode: String,
        name: String,
        metric: AlertMetric,
        comparisonOperator: ComparisonOperator,
        thresholdValue: Double,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.stockCode = stockCode
        self.name = name
        self.metric = metric
        self.comparisonOperator = comparisonOperator
        self.thresholdValue = thresholdValue
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func updating(
        name: String? = nil,
        metric: AlertMetric? = nil,
        comparisonOperator: ComparisonOperator? = nil,
        thresholdValue: Double? = nil,
        isEnabled: Bool? = nil,
        updatedAt: Date = Date()
    ) -> AlertRule {
        AlertRule(
            id: id,
            stockCode: stockCode,
            name: name ?? self.name,
            metric: metric ?? self.metric,
            comparisonOperator: comparisonOperator ?? self.comparisonOperator,
            thresholdValue: thresholdValue ?? self.thresholdValue,
            isEnabled: isEnabled ?? self.isEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

enum AlertRuleValidationError: Error, Equatable, Identifiable {
    case emptyName
    case invalidThreshold
    case negativeThreshold

    var id: String {
        message
    }

    var message: String {
        switch self {
        case .emptyName:
            return "条件名を入力してください。"
        case .invalidThreshold:
            return "しきい値は数値で入力してください。"
        case .negativeThreshold:
            return "しきい値は0以上で入力してください。"
        }
    }
}
