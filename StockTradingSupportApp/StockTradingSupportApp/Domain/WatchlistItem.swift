//
//  WatchlistItem.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct WatchlistItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let code: String
    let name: String
    let market: String
    let industry: String
    let isNikkei225: Bool
    let createdAt: Date

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

    init(seed: StockMasterSeed, id: UUID = UUID(), createdAt: Date = Date()) {
        self.init(
            id: id,
            code: seed.code,
            name: seed.name,
            market: seed.market,
            industry: seed.industry,
            isNikkei225: seed.isNikkei225,
            createdAt: createdAt
        )
    }
}
