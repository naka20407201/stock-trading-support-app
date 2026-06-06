//
//  StockMasterSeed.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct StockMasterSeedFile: Decodable {
    let sourceName: String
    let asOfDate: String
    let description: String
    let stocks: [StockMasterSeed]
}

struct StockMasterSeed: Identifiable, Decodable {
    var id: String { code }

    let code: String
    let name: String
    let market: String
    let industry: String
    let isNikkei225: Bool
    let isUserAdded: Bool
}
