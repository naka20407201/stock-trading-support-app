//
//  ManualStockSnapshotInputViewModel.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Combine
import Foundation

final class ManualStockSnapshotInputViewModel: ObservableObject {
    let stockCode: String

    @Published private(set) var input: ManualStockSnapshotInput?
    @Published private(set) var errorMessage: String?

    private let repository: any ManualStockSnapshotInputRepository

    init(
        stockCode: String,
        repository: any ManualStockSnapshotInputRepository
    ) {
        self.stockCode = stockCode
        self.repository = repository
        refresh()
    }

    func refresh() {
        let fetchedInput = repository.fetchInput(stockCode: stockCode)
        input = fetchedInput?.hasAnyValue == true ? fetchedInput : nil
        syncReadError()
    }

    @discardableResult
    func saveInput(
        currentPriceText: String,
        perText: String,
        pbrText: String,
        volumeText: String,
        updatedAt: Date = Date()
    ) throws -> ManualStockSnapshotInput {
        let input = ManualStockSnapshotInput(
            stockCode: stockCode,
            currentPrice: try parseOptionalValue(currentPriceText, field: .currentPrice),
            per: try parseOptionalValue(perText, field: .per),
            pbr: try parseOptionalValue(pbrText, field: .pbr),
            volume: try parseOptionalValue(volumeText, field: .volume),
            updatedAt: updatedAt
        )

        guard input.hasAnyValue else {
            throw ManualStockSnapshotInputValidationError.emptyValues
        }

        let savedInput = try repository.save(input)
        refresh()
        return savedInput
    }

    func deleteInput() {
        let didDelete = repository.delete(stockCode: stockCode)
        refresh()

        if !didDelete && errorMessage == nil {
            errorMessage = RepositoryStatusMessage.deleteFailed
        }
    }

    private func parseOptionalValue(
        _ text: String,
        field: ManualStockSnapshotInputField
    ) throws -> Double? {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return nil
        }

        guard let value = Double(normalizedText) else {
            throw ManualStockSnapshotInputValidationError.invalidNumber(field)
        }

        guard value >= 0 else {
            throw ManualStockSnapshotInputValidationError.negativeValue(field)
        }

        return value
    }

    private func syncReadError() {
        errorMessage = (repository as? any RepositoryReadStatusProviding)?.readErrorMessage
    }
}
