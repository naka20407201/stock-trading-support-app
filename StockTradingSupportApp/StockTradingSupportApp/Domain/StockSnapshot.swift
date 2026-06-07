//
//  StockSnapshot.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct StockSnapshot: Equatable {
    let stockCode: String
    let currentPrice: Double?
    let per: Double?
    let pbr: Double?
    let volume: Double?
    let capturedAt: Date
    let sourceName: String

    init(
        stockCode: String,
        currentPrice: Double? = nil,
        per: Double? = nil,
        pbr: Double? = nil,
        volume: Double? = nil,
        capturedAt: Date = Date(),
        sourceName: String
    ) {
        self.stockCode = stockCode
        self.currentPrice = currentPrice
        self.per = per
        self.pbr = pbr
        self.volume = volume
        self.capturedAt = capturedAt
        self.sourceName = sourceName
    }

    func value(for metric: AlertMetric) -> Double? {
        switch metric {
        case .currentPrice:
            return currentPrice
        case .per:
            return per
        case .pbr:
            return pbr
        case .volume:
            return volume
        }
    }
}
