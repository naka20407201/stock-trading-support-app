//
//  StockTradingSupportAppTests.swift
//  StockTradingSupportAppTests
//
//  Created by 中塚康喜 on 2026/06/07.
//

import Foundation
import SwiftData
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
    @Test func watchlistItemRecordConvertsToDomainModel() {
        let item = makeWatchlistItem(code: "7203", name: "トヨタ自動車")
        let record = WatchlistItemRecord(item: item)

        #expect(record.id == item.id)
        #expect(record.code == item.code)
        #expect(record.name == item.name)
        #expect(record.domainModel == item)
        #expect(WatchlistItem(record: record) == item)
    }

    @MainActor
    @Test func investmentMemoRecordConvertsToDomainModel() {
        let memo = makeInvestmentMemo(stockCode: "7203", title: "確認メモ")
        let record = InvestmentMemoRecord(memo: memo)

        #expect(record.id == memo.id)
        #expect(record.stockCode == memo.stockCode)
        #expect(record.title == memo.title)
        #expect(record.domainModel == memo)
        #expect(InvestmentMemo(record: record) == memo)
    }

    @MainActor
    @Test func alertRuleRecordConvertsToDomainModel() {
        let rule = makeAlertRule(stockCode: "7203", name: "現在値の確認")
        let record = AlertRuleRecord(rule: rule)

        #expect(record.id == rule.id)
        #expect(record.metricRawValue == rule.metric.rawValue)
        #expect(record.comparisonOperatorRawValue == rule.comparisonOperator.rawValue)
        #expect(record.domainModel == rule)
        #expect(AlertRule(record: record) == rule)
    }

    @MainActor
    @Test func alertMatchHistoryRecordConvertsToDomainModel() {
        let history = makeAlertMatchHistory(stockCode: "7203")
        let record = AlertMatchHistoryRecord(history: history)

        #expect(record.id == history.id)
        #expect(record.alertRuleName == history.alertRuleName)
        #expect(record.metricRawValue == history.metric.rawValue)
        #expect(record.domainModel == history)
        #expect(AlertMatchHistory(record: record) == history)
    }

    @MainActor
    @Test func swiftDataWatchlistRepositoryAddsAndFetchesItem() throws {
        let repository = try makeSwiftDataWatchlistRepository()
        let item = makeWatchlistItem(code: "6758", name: "ソニーグループ")

        try repository.add(item)
        let fetchedItems = repository.fetchItems()

        #expect(fetchedItems == [item])
        #expect(repository.contains(code: "6758"))
    }

    @MainActor
    @Test func swiftDataWatchlistRepositoryPreventsDuplicateCode() throws {
        let repository = try makeSwiftDataWatchlistRepository()
        let item = makeWatchlistItem(code: "9432", name: "日本電信電話")
        let duplicate = makeWatchlistItem(code: "9432", name: "日本電信電話")

        try repository.add(item)

        do {
            try repository.add(duplicate)
            Issue.record("SwiftDataRepositoryでも同じ銘柄コードの重複追加は失敗する必要があります。")
        } catch let error as WatchlistRepositoryError {
            #expect(error == .duplicateCode("9432"))
        } catch {
            Issue.record("想定外のエラーです: \(error)")
        }

        #expect(repository.fetchItems() == [item])
    }

    @MainActor
    @Test func swiftDataWatchlistRepositoryDeletesItem() throws {
        let repository = try makeSwiftDataWatchlistRepository()
        let item = makeWatchlistItem(code: "7203", name: "トヨタ自動車")

        try repository.add(item)
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
    @Test func swiftDataInvestmentMemoRepositoryAddsAndFetchesMemo() throws {
        let repository = try makeSwiftDataInvestmentMemoRepository()
        let memo = makeInvestmentMemo(stockCode: "7203", title: "決算前の確認")

        try repository.add(memo)
        let fetchedMemos = repository.fetchMemos(stockCode: "7203")

        #expect(fetchedMemos == [memo])
    }

    @MainActor
    @Test func swiftDataInvestmentMemoRepositoryUpdatesMemo() throws {
        let repository = try makeSwiftDataInvestmentMemoRepository()
        let memo = makeInvestmentMemo(stockCode: "7203", title: "確認メモ")
        let updatedMemo = memo.updating(
            title: "確認メモを更新",
            body: "入力内容を更新しました。",
            updatedAt: Date(timeIntervalSince1970: 100)
        )

        try repository.add(memo)
        try repository.update(updatedMemo)

        #expect(repository.fetchMemos(stockCode: "7203") == [updatedMemo])
    }

    @MainActor
    @Test func swiftDataInvestmentMemoRepositoryDeletesMemo() throws {
        let repository = try makeSwiftDataInvestmentMemoRepository()
        let memo = makeInvestmentMemo(stockCode: "7203", title: "確認メモ")

        try repository.add(memo)
        let didDelete = repository.delete(id: memo.id)

        #expect(didDelete)
        #expect(repository.fetchMemos(stockCode: "7203").isEmpty)
    }

    @MainActor
    @Test func swiftDataInvestmentMemoViewModelAddsMemo() throws {
        let viewModel = InvestmentMemoViewModel(
            stockCode: "7203",
            repository: try makeSwiftDataInvestmentMemoRepository()
        )

        try viewModel.addMemo(title: "確認メモ", body: "気になった点を記録しました。")

        #expect(viewModel.memos.count == 1)
        #expect(viewModel.memos.first?.stockCode == "7203")
        #expect(viewModel.memos.first?.title == "確認メモ")
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
    @Test func swiftDataAlertRuleRepositoryAddsAndFetchesRule() throws {
        let repository = try makeSwiftDataAlertRuleRepository()
        let rule = makeAlertRule(stockCode: "7203", name: "現在値の確認")

        try repository.add(rule)
        let fetchedRules = repository.fetchRules(stockCode: "7203")

        #expect(fetchedRules == [rule])
    }

    @MainActor
    @Test func swiftDataAlertRuleRepositoryUpdatesRule() throws {
        let repository = try makeSwiftDataAlertRuleRepository()
        let rule = makeAlertRule(stockCode: "7203", name: "現在値の確認")
        let updatedRule = rule.updating(
            name: "現在値の確認を更新",
            comparisonOperator: .lessThanOrEqual,
            thresholdValue: 2500,
            isEnabled: false,
            updatedAt: Date(timeIntervalSince1970: 100)
        )

        try repository.add(rule)
        try repository.update(updatedRule)

        #expect(repository.fetchRules(stockCode: "7203") == [updatedRule])
    }

    @MainActor
    @Test func swiftDataAlertRuleRepositoryDeletesRule() throws {
        let repository = try makeSwiftDataAlertRuleRepository()
        let rule = makeAlertRule(stockCode: "7203", name: "現在値の確認")

        try repository.add(rule)
        let didDelete = repository.delete(id: rule.id)

        #expect(didDelete)
        #expect(repository.fetchRules(stockCode: "7203").isEmpty)
    }

    @MainActor
    @Test func swiftDataAlertRuleRepositorySkipsInvalidRawValues() throws {
        let container = try makeSwiftDataModelContainer()
        let invalidRecord = AlertRuleRecord(
            stockCode: "7203",
            name: "復元できない条件",
            metricRawValue: "unknownMetric",
            comparisonOperatorRawValue: ComparisonOperator.greaterThanOrEqual.rawValue,
            thresholdValue: 3000
        )
        container.mainContext.insert(invalidRecord)
        try container.mainContext.save()

        let repository = SwiftDataAlertRuleRepository(modelContainer: container)

        #expect(repository.fetchRules(stockCode: "7203").isEmpty)
    }

    @MainActor
    @Test func swiftDataAlertRuleViewModelTogglesEnabled() throws {
        let rule = makeAlertRule(stockCode: "7203", name: "現在値の確認", isEnabled: true)
        let repository = try makeSwiftDataAlertRuleRepository()
        try repository.add(rule)
        let viewModel = AlertRuleViewModel(stockCode: "7203", repository: repository)

        try viewModel.toggleEnabled(id: rule.id)

        #expect(viewModel.rules.first?.isEnabled == false)
        #expect(repository.fetchRules(stockCode: "7203").first?.isEnabled == false)
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
    @Test func alertRuleViewModelTogglesEnabled() throws {
        let rule = makeAlertRule(stockCode: "7203", name: "現在値の確認", isEnabled: true)
        let viewModel = AlertRuleViewModel(
            stockCode: "7203",
            repository: InMemoryAlertRuleRepository(initialRules: [rule])
        )

        try viewModel.toggleEnabled(id: rule.id)

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

    @Test func alertRuleEvaluatorEvaluatesInitialComparisonOperators() {
        let evaluator = AlertRuleEvaluator()
        let snapshot = makeStockSnapshot(stockCode: "7203", currentPrice: 100)
        let cases: [(ComparisonOperator, Double)] = [
            (.greaterThan, 99),
            (.greaterThanOrEqual, 100),
            (.lessThan, 101),
            (.lessThanOrEqual, 100),
            (.equal, 100.00005),
            (.notEqual, 101)
        ]

        for (comparisonOperator, thresholdValue) in cases {
            let rule = makeAlertRule(
                stockCode: "7203",
                name: comparisonOperator.rawValue,
                comparisonOperator: comparisonOperator,
                thresholdValue: thresholdValue
            )

            let result = evaluator.evaluate(rule: rule, snapshot: snapshot)

            if case .matched(let observedValue) = result {
                #expect(observedValue == 100)
            } else {
                Issue.record("\(comparisonOperator.rawValue) は条件に一致する必要があります。")
            }
        }
    }

    @Test func alertRuleEvaluatorReturnsNotMatched() {
        let evaluator = AlertRuleEvaluator()
        let snapshot = makeStockSnapshot(stockCode: "7203", currentPrice: 100)
        let rule = makeAlertRule(
            stockCode: "7203",
            name: "現在値の確認",
            comparisonOperator: .greaterThan,
            thresholdValue: 100
        )

        let result = evaluator.evaluate(rule: rule, snapshot: snapshot)

        if case .notMatched(let observedValue) = result {
            #expect(observedValue == 100)
        } else {
            Issue.record("しきい値より大きくない場合は条件未一致になる必要があります。")
        }
    }

    @Test func alertRuleEvaluatorReturnsUnavailableWhenMetricValueIsMissing() {
        let evaluator = AlertRuleEvaluator()
        let snapshot = makeStockSnapshot(stockCode: "7203", currentPrice: 100)
        let rule = makeAlertRule(
            stockCode: "7203",
            name: "PERの確認",
            metric: .per,
            comparisonOperator: .greaterThanOrEqual,
            thresholdValue: 10
        )

        let result = evaluator.evaluate(rule: rule, snapshot: snapshot)

        if case .unavailable(let reason) = result {
            #expect(reason.contains("PER"))
        } else {
            Issue.record("対象指標値がない場合は評価できない結果になる必要があります。")
        }
    }

    @Test func alertRuleEvaluatorReturnsDisabledForDisabledRule() {
        let evaluator = AlertRuleEvaluator()
        let snapshot = makeStockSnapshot(stockCode: "7203", currentPrice: 100)
        let rule = makeAlertRule(
            stockCode: "7203",
            name: "現在値の確認",
            isEnabled: false
        )

        let result = evaluator.evaluate(rule: rule, snapshot: snapshot)

        #expect(result == .disabled)
    }

    @Test func mockStockDataProviderReturnsRepresentativeSnapshot() {
        let capturedAt = Date(timeIntervalSince1970: 100)
        let provider = MockStockDataProvider(capturedAt: capturedAt)

        let snapshot = provider.snapshot(for: "7203")

        #expect(snapshot?.stockCode == "7203")
        #expect(snapshot?.currentPrice == 3200)
        #expect(snapshot?.capturedAt == capturedAt)
        #expect(snapshot?.sourceName == "固定モック株価")
    }

    @Test func mockStockDataProviderUsesRequestTimeWhenCapturedAtIsNotInjected() {
        let provider = MockStockDataProvider()
        let before = Date()
        let snapshot = provider.snapshot(for: "7203")
        let after = Date()

        guard let capturedAt = snapshot?.capturedAt else {
            Issue.record("代表銘柄のSnapshotを取得できる必要があります。")
            return
        }

        #expect(capturedAt >= before)
        #expect(capturedAt <= after)
    }

    @Test func mockStockDataProviderReturnsNilForUndefinedCode() {
        let provider = MockStockDataProvider()

        let snapshot = provider.snapshot(for: "0000")

        #expect(snapshot == nil)
    }

    @Test func inMemoryAlertMatchHistoryRepositoryAddsHistory() throws {
        let repository = InMemoryAlertMatchHistoryRepository()
        let history = makeAlertMatchHistory(stockCode: "7203")

        try repository.add(history)
        let fetchedHistories = repository.fetchHistories(stockCode: "7203")

        #expect(fetchedHistories == [history])
    }

    @Test func inMemoryAlertMatchHistoryRepositoryFetchesOnlySpecifiedStockCode() throws {
        let targetHistory = makeAlertMatchHistory(
            id: UUID(uuidString: "BBBBBBBB-9999-8888-7777-BBBBBBBBBBBB")!,
            stockCode: "7203"
        )
        let otherHistory = makeAlertMatchHistory(
            id: UUID(uuidString: "CCCCCCCC-9999-8888-7777-CCCCCCCCCCCC")!,
            stockCode: "6758"
        )
        let repository = InMemoryAlertMatchHistoryRepository(initialHistories: [targetHistory, otherHistory])

        let fetchedHistories = repository.fetchHistories(stockCode: "7203")

        #expect(fetchedHistories == [targetHistory])
    }

    @Test func inMemoryAlertMatchHistoryRepositoryDeletesHistory() {
        let history = makeAlertMatchHistory(stockCode: "7203")
        let repository = InMemoryAlertMatchHistoryRepository(initialHistories: [history])

        let didDelete = repository.delete(id: history.id)

        #expect(didDelete)
        #expect(repository.fetchHistories(stockCode: "7203").isEmpty)
    }

    @Test func inMemoryAlertMatchHistoryRepositoryDeletesAllHistoriesForStockCode() {
        let targetHistory = makeAlertMatchHistory(
            id: UUID(uuidString: "BBBBBBBB-9999-8888-7777-BBBBBBBBBBBB")!,
            stockCode: "7203"
        )
        let otherHistory = makeAlertMatchHistory(
            id: UUID(uuidString: "CCCCCCCC-9999-8888-7777-CCCCCCCCCCCC")!,
            stockCode: "6758"
        )
        let repository = InMemoryAlertMatchHistoryRepository(initialHistories: [targetHistory, otherHistory])

        repository.deleteAll(stockCode: "7203")

        #expect(repository.fetchHistories(stockCode: "7203").isEmpty)
        #expect(repository.fetchHistories(stockCode: "6758") == [otherHistory])
    }

    @MainActor
    @Test func swiftDataAlertMatchHistoryRepositoryAddsAndFetchesHistory() throws {
        let repository = try makeSwiftDataAlertMatchHistoryRepository()
        let history = makeAlertMatchHistory(stockCode: "7203")

        try repository.add(history)
        let fetchedHistories = repository.fetchHistories(stockCode: "7203")

        #expect(fetchedHistories == [history])
    }

    @MainActor
    @Test func swiftDataAlertMatchHistoryRepositoryFetchesOnlySpecifiedStockCode() throws {
        let repository = try makeSwiftDataAlertMatchHistoryRepository()
        let targetHistory = makeAlertMatchHistory(
            id: UUID(uuidString: "BBBBBBBB-9999-8888-7777-BBBBBBBBBBBB")!,
            stockCode: "7203"
        )
        let otherHistory = makeAlertMatchHistory(
            id: UUID(uuidString: "CCCCCCCC-9999-8888-7777-CCCCCCCCCCCC")!,
            stockCode: "6758"
        )

        try repository.add(targetHistory)
        try repository.add(otherHistory)

        #expect(repository.fetchHistories(stockCode: "7203") == [targetHistory])
    }

    @MainActor
    @Test func swiftDataAlertMatchHistoryRepositoryDeletesHistory() throws {
        let repository = try makeSwiftDataAlertMatchHistoryRepository()
        let history = makeAlertMatchHistory(stockCode: "7203")

        try repository.add(history)
        let didDelete = repository.delete(id: history.id)

        #expect(didDelete)
        #expect(repository.fetchHistories(stockCode: "7203").isEmpty)
    }

    @MainActor
    @Test func swiftDataAlertMatchHistoryRepositoryDeletesAllHistoriesForStockCode() throws {
        let repository = try makeSwiftDataAlertMatchHistoryRepository()
        let targetHistory = makeAlertMatchHistory(
            id: UUID(uuidString: "BBBBBBBB-9999-8888-7777-BBBBBBBBBBBB")!,
            stockCode: "7203"
        )
        let otherHistory = makeAlertMatchHistory(
            id: UUID(uuidString: "CCCCCCCC-9999-8888-7777-CCCCCCCCCCCC")!,
            stockCode: "6758"
        )

        try repository.add(targetHistory)
        try repository.add(otherHistory)
        repository.deleteAll(stockCode: "7203")

        #expect(repository.fetchHistories(stockCode: "7203").isEmpty)
        #expect(repository.fetchHistories(stockCode: "6758") == [otherHistory])
    }

    @MainActor
    @Test func swiftDataAlertMatchHistoryRepositorySkipsInvalidRawValues() throws {
        let container = try makeSwiftDataModelContainer()
        let invalidRecord = AlertMatchHistoryRecord(
            stockCode: "7203",
            alertRuleId: UUID(uuidString: "AAAAAAAA-1111-2222-3333-EEEEEEEEEEEE")!,
            alertRuleName: "復元できない履歴",
            metricRawValue: AlertMetric.currentPrice.rawValue,
            comparisonOperatorRawValue: "unknownComparison",
            thresholdValue: 3000,
            observedValue: 3200,
            matchedAt: Date(timeIntervalSince1970: 0),
            sourceName: "テストデータ"
        )
        container.mainContext.insert(invalidRecord)
        try container.mainContext.save()

        let repository = SwiftDataAlertMatchHistoryRepository(modelContainer: container)

        #expect(repository.fetchHistories(stockCode: "7203").isEmpty)
    }

    @MainActor
    @Test func alertEvaluationViewModelCreatesHistoryWithSwiftDataRepositories() throws {
        let capturedAt = Date(timeIntervalSince1970: 1000)
        let rule = makeAlertRule(
            stockCode: "7203",
            name: "現在値の確認",
            comparisonOperator: .greaterThanOrEqual,
            thresholdValue: 3000
        )
        let alertRuleRepository = try makeSwiftDataAlertRuleRepository()
        let historyRepository = try makeSwiftDataAlertMatchHistoryRepository()
        try alertRuleRepository.add(rule)
        let viewModel = AlertEvaluationViewModel(
            stockCode: "7203",
            alertRuleRepository: alertRuleRepository,
            stockDataProvider: MockStockDataProvider(
                capturedAt: capturedAt,
                mockValues: ["7203": 3200]
            ),
            historyRepository: historyRepository
        )

        viewModel.evaluate()

        #expect(viewModel.histories.count == 1)
        #expect(historyRepository.fetchHistories(stockCode: "7203").first?.alertRuleId == rule.id)
        #expect(historyRepository.fetchHistories(stockCode: "7203").first?.matchedAt == capturedAt)
    }

    @MainActor
    @Test func alertEvaluationViewModelEvaluatesRulesAndCreatesHistory() {
        let capturedAt = Date(timeIntervalSince1970: 1000)
        let rule = makeAlertRule(
            stockCode: "7203",
            name: "現在値の確認",
            comparisonOperator: .greaterThanOrEqual,
            thresholdValue: 3000
        )
        let historyRepository = InMemoryAlertMatchHistoryRepository()
        let viewModel = AlertEvaluationViewModel(
            stockCode: "7203",
            alertRuleRepository: InMemoryAlertRuleRepository(initialRules: [rule]),
            stockDataProvider: MockStockDataProvider(
                capturedAt: capturedAt,
                mockValues: ["7203": 3200]
            ),
            historyRepository: historyRepository
        )

        viewModel.evaluate()

        #expect(viewModel.snapshot?.currentPrice == 3200)
        #expect(viewModel.evaluations.count == 1)
        #expect(viewModel.evaluations.first?.result == .matched(observedValue: 3200))
        #expect(viewModel.histories.count == 1)
        #expect(viewModel.histories.first?.alertRuleId == rule.id)
        #expect(viewModel.histories.first?.matchedAt == capturedAt)
    }

    @MainActor
    @Test func alertEvaluationViewModelDoesNotDuplicateHistoryForSameSnapshotAndRule() {
        let capturedAt = Date(timeIntervalSince1970: 1000)
        let rule = makeAlertRule(
            stockCode: "7203",
            name: "現在値の確認",
            comparisonOperator: .greaterThanOrEqual,
            thresholdValue: 3000
        )
        let viewModel = AlertEvaluationViewModel(
            stockCode: "7203",
            alertRuleRepository: InMemoryAlertRuleRepository(initialRules: [rule]),
            stockDataProvider: MockStockDataProvider(
                capturedAt: capturedAt,
                mockValues: ["7203": 3200]
            ),
            historyRepository: InMemoryAlertMatchHistoryRepository()
        )

        viewModel.evaluate()
        viewModel.evaluate()

        #expect(viewModel.histories.count == 1)
    }

    @MainActor
    @Test func alertEvaluationViewModelReportsHistorySaveFailure() {
        let rule = makeAlertRule(
            stockCode: "7203",
            name: "現在値の確認",
            comparisonOperator: .greaterThanOrEqual,
            thresholdValue: 3000
        )
        let viewModel = AlertEvaluationViewModel(
            stockCode: "7203",
            alertRuleRepository: InMemoryAlertRuleRepository(initialRules: [rule]),
            stockDataProvider: MockStockDataProvider(
                capturedAt: Date(timeIntervalSince1970: 1000),
                mockValues: ["7203": 3200]
            ),
            historyRepository: FailingAlertMatchHistoryRepository()
        )

        viewModel.evaluate()

        #expect(viewModel.errorMessage == "条件一致履歴を保存できませんでした。")
        #expect(viewModel.evaluations.first?.result == .matched(observedValue: 3200))
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

    private func makeStockSnapshot(
        stockCode: String,
        currentPrice: Double?,
        per: Double? = nil,
        pbr: Double? = nil,
        volume: Double? = nil,
        capturedAt: Date = Date(timeIntervalSince1970: 0),
        sourceName: String = "テストデータ"
    ) -> StockSnapshot {
        StockSnapshot(
            stockCode: stockCode,
            currentPrice: currentPrice,
            per: per,
            pbr: pbr,
            volume: volume,
            capturedAt: capturedAt,
            sourceName: sourceName
        )
    }

    private func makeAlertMatchHistory(
        id: UUID = UUID(uuidString: "AAAAAAAA-9999-8888-7777-EEEEEEEEEEEE")!,
        stockCode: String,
        alertRuleId: UUID = UUID(uuidString: "AAAAAAAA-1111-2222-3333-EEEEEEEEEEEE")!,
        alertRuleName: String = "現在値の確認",
        metric: AlertMetric = .currentPrice,
        comparisonOperator: ComparisonOperator = .greaterThanOrEqual,
        thresholdValue: Double = 3000,
        observedValue: Double = 3200,
        matchedAt: Date = Date(timeIntervalSince1970: 0),
        sourceName: String = "テストデータ"
    ) -> AlertMatchHistory {
        AlertMatchHistory(
            id: id,
            stockCode: stockCode,
            alertRuleId: alertRuleId,
            alertRuleName: alertRuleName,
            metric: metric,
            comparisonOperator: comparisonOperator,
            thresholdValue: thresholdValue,
            observedValue: observedValue,
            matchedAt: matchedAt,
            sourceName: sourceName
        )
    }

    @MainActor
    private func makeSwiftDataWatchlistRepository() throws -> SwiftDataWatchlistRepository {
        try SwiftDataWatchlistRepository(modelContainer: makeSwiftDataModelContainer())
    }

    @MainActor
    private func makeSwiftDataInvestmentMemoRepository() throws -> SwiftDataInvestmentMemoRepository {
        try SwiftDataInvestmentMemoRepository(modelContainer: makeSwiftDataModelContainer())
    }

    @MainActor
    private func makeSwiftDataAlertRuleRepository() throws -> SwiftDataAlertRuleRepository {
        try SwiftDataAlertRuleRepository(modelContainer: makeSwiftDataModelContainer())
    }

    @MainActor
    private func makeSwiftDataAlertMatchHistoryRepository() throws -> SwiftDataAlertMatchHistoryRepository {
        try SwiftDataAlertMatchHistoryRepository(modelContainer: makeSwiftDataModelContainer())
    }

    @MainActor
    private func makeSwiftDataModelContainer() throws -> ModelContainer {
        let schema = Schema([
            PersistenceSchemaPlaceholder.self,
            WatchlistItemRecord.self,
            InvestmentMemoRecord.self,
            AlertRuleRecord.self,
            AlertMatchHistoryRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

}

private enum FailingAlertMatchHistoryRepositoryError: Error {
    case saveFailed
}

private final class FailingAlertMatchHistoryRepository: AlertMatchHistoryRepository {
    func fetchHistories(stockCode: String) -> [AlertMatchHistory] {
        []
    }

    @discardableResult
    func add(_ history: AlertMatchHistory) throws -> AlertMatchHistory {
        throw FailingAlertMatchHistoryRepositoryError.saveFailed
    }

    @discardableResult
    func delete(id: AlertMatchHistory.ID) -> Bool {
        false
    }

    func deleteAll(stockCode: String) {}
}
