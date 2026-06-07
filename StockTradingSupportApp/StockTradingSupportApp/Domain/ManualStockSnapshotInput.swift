//
//  ManualStockSnapshotInput.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct ManualStockSnapshotInput: Identifiable, Equatable, Hashable {
    let id: UUID
    let stockCode: String
    let currentPrice: Double?
    let per: Double?
    let pbr: Double?
    let volume: Double?
    let updatedAt: Date
    let sourceName: String

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

    var hasAnyValue: Bool {
        currentPrice != nil || per != nil || pbr != nil || volume != nil
    }

    var stockSnapshot: StockSnapshot {
        StockSnapshot(
            stockCode: stockCode,
            currentPrice: currentPrice,
            per: per,
            pbr: pbr,
            volume: volume,
            capturedAt: updatedAt,
            sourceName: sourceName
        )
    }
}

enum ManualStockSnapshotInputField: String, CaseIterable, Identifiable {
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

    var metric: AlertMetric {
        switch self {
        case .currentPrice:
            return .currentPrice
        case .per:
            return .per
        case .pbr:
            return .pbr
        case .volume:
            return .volume
        }
    }
}

enum ManualStockSnapshotInputValidationError: Error, Equatable, Identifiable {
    case invalidNumber(ManualStockSnapshotInputField)
    case negativeValue(ManualStockSnapshotInputField)

    var id: String {
        message
    }

    var message: String {
        switch self {
        case .invalidNumber(let field):
            return "\(field.displayName)は数値で入力してください。"
        case .negativeValue(let field):
            return "\(field.displayName)は0以上で入力してください。"
        }
    }
}
