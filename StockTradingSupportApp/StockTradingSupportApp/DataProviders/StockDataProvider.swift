//
//  StockDataProvider.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

protocol StockDataProviding {
    func snapshot(for stockCode: String) -> StockSnapshot?
}

struct MockStockDataProvider: StockDataProviding {
    private let sourceName: String
    private let fixedCapturedAt: Date?
    private let mockValues: [String: Double]

    init(
        sourceName: String = "固定モック株価",
        capturedAt: Date? = nil,
        mockValues: [String: Double] = [
            "7203": 3200,
            "6758": 14500,
            "9984": 8600,
            "8035": 35000,
            "9432": 155
        ]
    ) {
        self.sourceName = sourceName
        self.fixedCapturedAt = capturedAt
        self.mockValues = mockValues
    }

    func snapshot(for stockCode: String) -> StockSnapshot? {
        guard let currentPrice = mockValues[stockCode] else {
            return nil
        }

        return StockSnapshot(
            stockCode: stockCode,
            currentPrice: currentPrice,
            capturedAt: fixedCapturedAt ?? Date(),
            sourceName: sourceName
        )
    }
}
