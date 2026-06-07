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

    @MainActor
    @Test func watchlistViewModelDeletesCapturedIdsForMultipleSelection() {
        let firstItem = makeWatchlistItem(code: "7203", name: "トヨタ自動車")
        let secondItem = makeWatchlistItem(code: "6758", name: "ソニーグループ")
        let thirdItem = makeWatchlistItem(code: "9432", name: "日本電信電話")
        let viewModel = WatchlistViewModel(
            repository: InMemoryWatchlistRepository(initialItems: [firstItem, secondItem, thirdItem])
        )

        let idsToDelete = [viewModel.items[0].id, viewModel.items[2].id]
        for id in idsToDelete {
            viewModel.delete(id: id)
        }

        #expect(viewModel.items == [secondItem])
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

    @Test func customStockInputValidatorAllowsOnlyHalfWidthFourDigitCode() {
        let validator = CustomStockInputValidator()
        let validInput = CustomStockInput(
            code: "1234",
            name: "テスト銘柄",
            market: "TSE Prime",
            industry: "情報・通信業"
        )

        #expect(validator.validate(validInput) { _ in false }.isEmpty)

        for code in ["123", "12345", "12A4", "１２３４"] {
            let input = CustomStockInput(
                code: code,
                name: "テスト銘柄",
                market: "TSE Prime",
                industry: "情報・通信業"
            )

            let errors = validator.validate(input) { _ in false }

            #expect(errors.contains(.invalidCode))
        }
    }

    @Test func inMemoryInvestmentMemoRepositoryAddsMemo() throws {
        let repository = InMemoryInvestmentMemoRepository()
        let memo = makeInvestmentMemo(stockCode: "7203", title: "決算前の確認")

        try repository.add(memo)
        let fetchedMemos = repository.fetchMemos(stockCode: "7203")

        #expect(fetchedMemos == [memo])
    }

    @Test func inMemoryInvestmentMemoRepositoryFetchesOnlySpecifiedStockCode() throws {
        let targetMemo = makeInvestmentMemo(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            stockCode: "7203",
            title: "トヨタ自動車の確認"
        )
        let otherMemo = makeInvestmentMemo(
            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
            stockCode: "6758",
            title: "ソニーグループの確認"
        )
        let repository = InMemoryInvestmentMemoRepository(initialMemos: [targetMemo, otherMemo])

        let fetchedMemos = repository.fetchMemos(stockCode: "7203")

        #expect(fetchedMemos == [targetMemo])
    }

    @Test func inMemoryInvestmentMemoRepositoryUpdatesMemo() throws {
        let memo = makeInvestmentMemo(stockCode: "7203", title: "確認メモ")
        let repository = InMemoryInvestmentMemoRepository(initialMemos: [memo])
        let updatedMemo = memo.updating(
            title: "確認メモを更新",
            body: "入力内容を更新しました。",
            updatedAt: Date(timeIntervalSince1970: 100)
        )

        try repository.update(updatedMemo)
        let fetchedMemo = repository.fetchMemos(stockCode: "7203").first

        #expect(fetchedMemo == updatedMemo)
    }

    @Test func inMemoryInvestmentMemoRepositoryDeletesMemo() {
        let memo = makeInvestmentMemo(stockCode: "7203", title: "確認メモ")
        let repository = InMemoryInvestmentMemoRepository(initialMemos: [memo])

        let didDelete = repository.delete(id: memo.id)

        #expect(didDelete)
        #expect(repository.fetchMemos(stockCode: "7203").isEmpty)
    }

    @MainActor
    @Test func investmentMemoViewModelAddsMemo() throws {
        let viewModel = InvestmentMemoViewModel(
            stockCode: "7203",
            repository: InMemoryInvestmentMemoRepository()
        )

        try viewModel.addMemo(title: "確認メモ", body: "気になった点を記録しました。")

        #expect(viewModel.memos.count == 1)
        #expect(viewModel.memos.first?.stockCode == "7203")
        #expect(viewModel.memos.first?.title == "確認メモ")
    }

    @MainActor
    @Test func investmentMemoViewModelRejectsEmptyTitle() throws {
        let viewModel = InvestmentMemoViewModel(
            stockCode: "7203",
            repository: InMemoryInvestmentMemoRepository()
        )

        do {
            try viewModel.addMemo(title: " ", body: "本文だけの入力です。")
            Issue.record("タイトルが空の確認メモは追加しない必要があります。")
        } catch let error as InvestmentMemoValidationError {
            #expect(error == .emptyTitle)
        } catch {
            Issue.record("想定外のエラーです: \(error)")
        }

        #expect(viewModel.memos.isEmpty)
    }

    @MainActor
    @Test func investmentMemoViewModelDeletesCapturedIdsForMultipleSelection() {
        let firstMemo = makeInvestmentMemo(
            id: UUID(uuidString: "11111111-AAAA-BBBB-CCCC-111111111111")!,
            stockCode: "7203",
            title: "確認メモ1",
            updatedAt: Date(timeIntervalSince1970: 3)
        )
        let secondMemo = makeInvestmentMemo(
            id: UUID(uuidString: "22222222-AAAA-BBBB-CCCC-222222222222")!,
            stockCode: "7203",
            title: "確認メモ2",
            updatedAt: Date(timeIntervalSince1970: 2)
        )
        let thirdMemo = makeInvestmentMemo(
            id: UUID(uuidString: "33333333-AAAA-BBBB-CCCC-333333333333")!,
            stockCode: "7203",
            title: "確認メモ3",
            updatedAt: Date(timeIntervalSince1970: 1)
        )
        let viewModel = InvestmentMemoViewModel(
            stockCode: "7203",
            repository: InMemoryInvestmentMemoRepository(initialMemos: [firstMemo, secondMemo, thirdMemo])
        )

        let idsToDelete = [viewModel.memos[0].id, viewModel.memos[2].id]
        for id in idsToDelete {
            viewModel.deleteMemo(id: id)
        }

        #expect(viewModel.memos == [secondMemo])
    }

    @Test func inMemoryAlertRuleRepositoryAddsRule() throws {
        let repository = InMemoryAlertRuleRepository()
        let rule = makeAlertRule(stockCode: "7203", name: "現在値の確認")

        try repository.add(rule)
        let fetchedRules = repository.fetchRules(stockCode: "7203")

        #expect(fetchedRules == [rule])
    }

    @Test func inMemoryAlertRuleRepositoryFetchesOnlySpecifiedStockCode() throws {
        let targetRule = makeAlertRule(
            id: UUID(uuidString: "BBBBBBBB-1111-2222-3333-BBBBBBBBBBBB")!,
            stockCode: "7203",
            name: "トヨタ自動車の確認"
        )
        let otherRule = makeAlertRule(
            id: UUID(uuidString: "CCCCCCCC-1111-2222-3333-CCCCCCCCCCCC")!,
            stockCode: "6758",
            name: "ソニーグループの確認"
        )
        let repository = InMemoryAlertRuleRepository(initialRules: [targetRule, otherRule])

        let fetchedRules = repository.fetchRules(stockCode: "7203")

        #expect(fetchedRules == [targetRule])
    }

    @Test func inMemoryAlertRuleRepositoryUpdatesRule() throws {
        let rule = makeAlertRule(stockCode: "7203", name: "現在値の確認")
        let repository = InMemoryAlertRuleRepository(initialRules: [rule])
        let updatedRule = rule.updating(
            name: "現在値の確認を更新",
            comparisonOperator: .lessThanOrEqual,
            thresholdValue: 2500,
            isEnabled: false,
            updatedAt: Date(timeIntervalSince1970: 100)
        )

        try repository.update(updatedRule)
        let fetchedRule = repository.fetchRules(stockCode: "7203").first

        #expect(fetchedRule == updatedRule)
    }

    @Test func inMemoryAlertRuleRepositoryDeletesRule() {
        let rule = makeAlertRule(stockCode: "7203", name: "現在値の確認")
        let repository = InMemoryAlertRuleRepository(initialRules: [rule])

        let didDelete = repository.delete(id: rule.id)

        #expect(didDelete)
        #expect(repository.fetchRules(stockCode: "7203").isEmpty)
    }

    @MainActor
    @Test func alertRuleViewModelAddsRule() throws {
        let viewModel = AlertRuleViewModel(
            stockCode: "7203",
            repository: InMemoryAlertRuleRepository()
        )

        try viewModel.addRule(
            name: "現在値の確認",
            metric: .currentPrice,
            comparisonOperator: .greaterThanOrEqual,
            thresholdValueText: "3000",
            isEnabled: true
        )

        #expect(viewModel.rules.count == 1)
        #expect(viewModel.rules.first?.stockCode == "7203")
        #expect(viewModel.rules.first?.thresholdValue == 3000)
    }

    @MainActor
    @Test func alertRuleViewModelRejectsEmptyName() throws {
        let viewModel = AlertRuleViewModel(
            stockCode: "7203",
            repository: InMemoryAlertRuleRepository()
        )

        do {
            try viewModel.addRule(
                name: " ",
                metric: .currentPrice,
                comparisonOperator: .greaterThanOrEqual,
                thresholdValueText: "3000",
                isEnabled: true
            )
            Issue.record("条件名が空の条件は追加しない必要があります。")
        } catch let error as AlertRuleValidationError {
            #expect(error == .emptyName)
        } catch {
            Issue.record("想定外のエラーです: \(error)")
        }

        #expect(viewModel.rules.isEmpty)
    }

    @MainActor
    @Test func alertRuleViewModelRejectsNonNumericThreshold() throws {
        let viewModel = AlertRuleViewModel(
            stockCode: "7203",
            repository: InMemoryAlertRuleRepository()
        )

        do {
            try viewModel.addRule(
                name: "現在値の確認",
                metric: .currentPrice,
                comparisonOperator: .greaterThanOrEqual,
                thresholdValueText: "abc",
                isEnabled: true
            )
            Issue.record("数値ではないしきい値は追加しない必要があります。")
        } catch let error as AlertRuleValidationError {
            #expect(error == .invalidThreshold)
        } catch {
            Issue.record("想定外のエラーです: \(error)")
        }

        #expect(viewModel.rules.isEmpty)
    }

    @MainActor
    @Test func alertRuleViewModelRejectsNegativeThreshold() throws {
        let viewModel = AlertRuleViewModel(
            stockCode: "7203",
            repository: InMemoryAlertRuleRepository()
        )

        do {
            try viewModel.addRule(
                name: "現在値の確認",
                metric: .currentPrice,
                comparisonOperator: .greaterThanOrEqual,
                thresholdValueText: "-1",
                isEnabled: true
            )
            Issue.record("0未満のしきい値は追加しない必要があります。")
        } catch let error as AlertRuleValidationError {
            #expect(error == .negativeThreshold)
        } catch {
            Issue.record("想定外のエラーです: \(error)")
        }

        #expect(viewModel.rules.isEmpty)
    }

    @MainActor
    @Test func alertRuleViewModelTogglesEnabled() {
        let rule = makeAlertRule(stockCode: "7203", name: "現在値の確認", isEnabled: true)
        let viewModel = AlertRuleViewModel(
            stockCode: "7203",
            repository: InMemoryAlertRuleRepository(initialRules: [rule])
        )

        viewModel.toggleEnabled(id: rule.id)

        #expect(viewModel.rules.first?.isEnabled == false)
    }

    @Test func comparisonOperatorDefinesInitialSixCases() {
        #expect(ComparisonOperator.allCases == [
            .greaterThan,
            .greaterThanOrEqual,
            .lessThan,
            .lessThanOrEqual,
            .equal,
            .notEqual
        ])
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

    private func makeInvestmentMemo(
        id: UUID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
        stockCode: String,
        title: String,
        body: String = "確認した内容です。",
        createdAt: Date = Date(timeIntervalSince1970: 0),
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> InvestmentMemo {
        InvestmentMemo(
            id: id,
            stockCode: stockCode,
            title: title,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func makeAlertRule(
        id: UUID = UUID(uuidString: "AAAAAAAA-1111-2222-3333-EEEEEEEEEEEE")!,
        stockCode: String,
        name: String,
        metric: AlertMetric = .currentPrice,
        comparisonOperator: ComparisonOperator = .greaterThanOrEqual,
        thresholdValue: Double = 3000,
        isEnabled: Bool = true,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> AlertRule {
        AlertRule(
            id: id,
            stockCode: stockCode,
            name: name,
            metric: metric,
            comparisonOperator: comparisonOperator,
            thresholdValue: thresholdValue,
            isEnabled: isEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

}
