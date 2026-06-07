//
//  InvestmentMemoViewModel.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Combine
import Foundation

final class InvestmentMemoViewModel: ObservableObject {
    let stockCode: String

    @Published private(set) var memos: [InvestmentMemo] = []

    private let repository: any InvestmentMemoRepository

    init(
        stockCode: String,
        repository: any InvestmentMemoRepository
    ) {
        self.stockCode = stockCode
        self.repository = repository
        refresh()
    }

    func refresh() {
        memos = repository.fetchMemos(stockCode: stockCode)
    }

    @discardableResult
    func addMemo(title: String, body: String) throws -> InvestmentMemo {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedTitle.isEmpty else {
            throw InvestmentMemoValidationError.emptyTitle
        }

        let memo = InvestmentMemo(
            stockCode: stockCode,
            title: normalizedTitle,
            body: normalizedBody
        )

        let addedMemo = try repository.add(memo)
        refresh()
        return addedMemo
    }

    @discardableResult
    func updateMemo(id: InvestmentMemo.ID, title: String, body: String) throws -> InvestmentMemo {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedTitle.isEmpty else {
            throw InvestmentMemoValidationError.emptyTitle
        }

        guard let existingMemo = memos.first(where: { $0.id == id }) else {
            throw InvestmentMemoRepositoryError.memoNotFound(id)
        }

        let updatedMemo = existingMemo.updating(
            title: normalizedTitle,
            body: normalizedBody
        )

        let savedMemo = try repository.update(updatedMemo)
        refresh()
        return savedMemo
    }

    func deleteMemo(id: InvestmentMemo.ID) {
        _ = repository.delete(id: id)
        refresh()
    }
}
