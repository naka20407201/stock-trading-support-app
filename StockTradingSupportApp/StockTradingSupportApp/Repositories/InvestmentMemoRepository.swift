//
//  InvestmentMemoRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

protocol InvestmentMemoRepository: AnyObject {
    func fetchMemos(stockCode: String) -> [InvestmentMemo]
    @discardableResult func add(_ memo: InvestmentMemo) throws -> InvestmentMemo
    @discardableResult func update(_ memo: InvestmentMemo) throws -> InvestmentMemo
    @discardableResult func delete(id: InvestmentMemo.ID) -> Bool
}

enum InvestmentMemoRepositoryError: Error, Equatable {
    case memoNotFound(UUID)
}

final class InMemoryInvestmentMemoRepository: InvestmentMemoRepository {
    private var memos: [InvestmentMemo]

    init(initialMemos: [InvestmentMemo] = []) {
        self.memos = initialMemos
    }

    func fetchMemos(stockCode: String) -> [InvestmentMemo] {
        memos
            .filter { $0.stockCode == stockCode }
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.createdAt > rhs.createdAt
                }

                return lhs.updatedAt > rhs.updatedAt
            }
    }

    @discardableResult
    func add(_ memo: InvestmentMemo) throws -> InvestmentMemo {
        memos.append(memo)
        return memo
    }

    @discardableResult
    func update(_ memo: InvestmentMemo) throws -> InvestmentMemo {
        guard let index = memos.firstIndex(where: { $0.id == memo.id }) else {
            throw InvestmentMemoRepositoryError.memoNotFound(memo.id)
        }

        memos[index] = memo
        return memo
    }

    @discardableResult
    func delete(id: InvestmentMemo.ID) -> Bool {
        guard let index = memos.firstIndex(where: { $0.id == id }) else {
            return false
        }

        memos.remove(at: index)
        return true
    }
}
