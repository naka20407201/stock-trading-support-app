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
        let fetchedItems = repository.fetchItems()

        #expect(fetchedItems.count == 1)
        #expect(fetchedItems.first?.id == item.id)
        #expect(fetchedItems.first?.code == item.code)
    }

    @Test func inMemoryWatchlistRepositoryAddsItem() throws {
        let repository = InMemoryWatchlistRepository()
        let item = makeWatchlistItem(code: "6758", name: "ソニーグループ")

        try repository.add(item)
        let fetchedItems = repository.fetchItems()

        #expect(fetchedItems.count == 1)
        #expect(fetchedItems.first?.id == item.id)
        #expect(fetchedItems.first?.code == item.code)
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

        let fetchedItems = repository.fetchItems()
        #expect(fetchedItems.count == 1)
        #expect(fetchedItems.first?.id == item.id)
        #expect(fetchedItems.first?.code == item.code)
    }

    @Test func inMemoryWatchlistRepositoryDeletesItem() {
        let item = makeWatchlistItem(code: "7203", name: "トヨタ自動車")
        let repository = InMemoryWatchlistRepository(initialItems: [item])

        let didDelete = repository.delete(id: item.id)

        #expect(didDelete)
        #expect(repository.fetchItems().isEmpty)
        #expect(!repository.contains(code: "7203"))
    }

    @MainActor
    @Test func watchlistViewModelFetchesInitialItems() {
        let item = makeWatchlistItem(code: "7203", name: "トヨタ自動車")
        let viewModel = WatchlistViewModel(
            repository: InMemoryWatchlistRepository(initialItems: [item])
        )

        #expect(viewModel.items == [item])
    }

    @MainActor
    @Test func watchlistViewModelAddsItem() throws {
        let viewModel = WatchlistViewModel(repository: InMemoryWatchlistRepository())
        let item = makeWatchlistItem(code: "6758", name: "ソニーグループ")

        try viewModel.add(item)

        #expect(viewModel.items == [item])
        #expect(viewModel.contains(code: "6758"))
    }

    @MainActor
    @Test func watchlistViewModelPreventsDuplicateCode() throws {
        let item = makeWatchlistItem(code: "9432", name: "日本電信電話")
        let duplicate = makeWatchlistItem(code: "9432", name: "日本電信電話")
        let viewModel = WatchlistViewModel(
            repository: InMemoryWatchlistRepository(initialItems: [item])
        )

        do {
            try viewModel.add(duplicate)
            Issue.record("ViewModel経由でも同じ銘柄コードの重複追加は失敗する必要があります。")
        } catch let error as WatchlistRepositoryError {
            #expect(error == .duplicateCode("9432"))
        } catch {
            Issue.record("想定外のエラーです: \(error)")
        }

        #expect(viewModel.items == [item])
    }

    @Test func customStockInputValidatorRejectsInvalidCode() {
        let validator = CustomStockInputValidator()
        let input = CustomStockInput(
            code: "12A4",
            name: "テスト銘柄",
            market: "TSE Prime",
            industry: "情報・通信業"
        )

        let errors = validator.validate(input) { _ in false }

        #expect(errors.contains(.invalidCode))
    }

    @Test func customStockInputValidatorRejectsEmptyName() {
        let validator = CustomStockInputValidator()
        let input = CustomStockInput(
            code: "1234",
            name: " ",
            market: "TSE Prime",
            industry: "情報・通信業"
        )

        let errors = validator.validate(input) { _ in false }

        #expect(errors.contains(.emptyName))
    }

    @Test func customStockInputValidatorRejectsDuplicateCode() {
        let validator = CustomStockInputValidator()
        let input = CustomStockInput(
            code: "7203",
            name: "トヨタ自動車",
            market: "TSE Prime",
            industry: "輸送用機器"
        )

        let errors = validator.validate(input) { code in
            code == "7203"
        }

        #expect(errors.contains(.duplicateCode))
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
