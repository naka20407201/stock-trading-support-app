//
//  StockTradingSupportAppTests.swift
//  StockTradingSupportAppTests
//
//  Created by 中塚康喜 on 2026/06/07.
//

import Testing
@testable import StockTradingSupportApp

struct StockTradingSupportAppTests {

    @Test func loadsNikkei225MockStockMaster() throws {
        let provider = LocalStockMasterProvider()
        let seedFile = try provider.loadSeedFile()

        #expect(seedFile.sourceName == "nikkei225Mock")
        #expect(seedFile.asOfDate == "2026-06-07")
        #expect(seedFile.stocks.count == 25)
        #expect(seedFile.stocks.contains { stock in
            stock.code == "7203" && stock.name == "トヨタ自動車"
        })
    }

}
