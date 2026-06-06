//
//  StockTradingSupportAppTests.swift
//  StockTradingSupportAppTests
//
//  Created by 中塚康喜 on 2026/06/07.
//

import Foundation
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

    @Test func nikkei225MockStockMasterHasNonEmptyUniqueFourDigitCodes() throws {
        let provider = LocalStockMasterProvider()
        let seedFile = try provider.loadSeedFile()

        let codes = seedFile.stocks.map(\.code)

        #expect(!seedFile.stocks.isEmpty)
        #expect(codes.allSatisfy { code in
            code.count == 4 && code.allSatisfy(\.isNumber)
        })
        #expect(Set(codes).count == codes.count)
    }

    @Test func inMemoryWatchlistRepositoryFetchesInitialItems() {
        let item = makeWatchlistItem(code: "7203", name: "トヨタ自動車")
        let repository = InMemoryWatchlistRepository(initialItems: [item])

        #expect(repository.fetchItems() == [item])
    }

    @Test func inMemoryWatchlistRepositoryAddsItem() throws {
        let repository = InMemoryWatchlistRepository()
        let item = makeWatchlistItem(code: "6758", name: "ソニーグループ")

        try repository.add(item)

        #expect(repository.fetchItems() == [item])
        #expect(repository.contains(code: "6758"))
    }

    @Test func inMemoryWatchlistRepositoryPreventsDuplicateCode() throws {
        let item = makeWatchlistItem(code: "9432", name: "日本電信電話")
        let duplicate = makeWatchlistItem(code: "9432", name: "日本電信電話")
        let repository = InMemoryWatchlistRepository(initialItems: [item])

        do {
            try repository.add(duplicate)
            Issue.record("同じ銘柄コードの重複追加は失敗する必要があります。")
        } catch let error as WatchlistRepositoryError {
            #expect(error == .duplicateCode("9432"))
        } catch {
            Issue.record("想定外のエラーです: \(error)")
        }

        #expect(repository.fetchItems() == [item])
    }

    @Test func inMemoryWatchlistRepositoryDeletesItem() {
        let item = makeWatchlistItem(code: "7203", name: "トヨタ自動車")
        let repository = InMemoryWatchlistRepository(initialItems: [item])

        let didDelete = repository.delete(id: item.id)

        #expect(didDelete)
        #expect(repository.fetchItems().isEmpty)
        #expect(!repository.contains(code: "7203"))
    }

    private func makeWatchlistItem(code: String, name: String) -> WatchlistItem {
        WatchlistItem(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-\(code)\(code)\(code)")!,
            code: code,
            name: name,
            market: "TSE Prime",
            industry: "テスト業種",
            isNikkei225: true,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

}
