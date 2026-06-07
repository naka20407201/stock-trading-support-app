//
//  SwiftDataInvestmentMemoRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation
import SwiftData

final class SwiftDataInvestmentMemoRepository: InvestmentMemoRepository {
    // The container is retained to keep in-memory test stores alive for the repository lifetime.
    private let modelContainer: ModelContainer?
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContainer = nil
        self.modelContext = modelContext
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }

    func fetchMemos(stockCode: String) -> [InvestmentMemo] {
        do {
            return try fetchRecords()
                .filter { $0.stockCode == stockCode }
                .map(\.domainModel)
                .sorted { lhs, rhs in
                    if lhs.updatedAt == rhs.updatedAt {
                        return lhs.createdAt > rhs.createdAt
                    }

                    return lhs.updatedAt > rhs.updatedAt
                }
        } catch {
            // TODO: Surface persistence read failures through ViewModel state instead of showing an empty list.
            return []
        }
    }

    @discardableResult
    func add(_ memo: InvestmentMemo) throws -> InvestmentMemo {
        let record = InvestmentMemoRecord(memo: memo)
        modelContext.insert(record)

        do {
            try modelContext.save()
            return memo
        } catch {
            modelContext.rollback()
            throw InvestmentMemoRepositoryError.persistenceFailure(error.localizedDescription)
        }
    }

    @discardableResult
    func update(_ memo: InvestmentMemo) throws -> InvestmentMemo {
        do {
            guard let record = try fetchRecords().first(where: { $0.id == memo.id }) else {
                throw InvestmentMemoRepositoryError.memoNotFound(memo.id)
            }

            record.stockCode = memo.stockCode
            record.title = memo.title
            record.body = memo.body
            record.createdAt = memo.createdAt
            record.updatedAt = memo.updatedAt

            try modelContext.save()
            return memo
        } catch let error as InvestmentMemoRepositoryError {
            throw error
        } catch {
            modelContext.rollback()
            throw InvestmentMemoRepositoryError.persistenceFailure(error.localizedDescription)
        }
    }

    @discardableResult
    func delete(id: InvestmentMemo.ID) -> Bool {
        do {
            guard let record = try fetchRecords().first(where: { $0.id == id }) else {
                return false
            }

            modelContext.delete(record)
            try modelContext.save()
            return true
        } catch {
            modelContext.rollback()
            return false
        }
    }

    private func fetchRecords() throws -> [InvestmentMemoRecord] {
        try modelContext.fetch(FetchDescriptor<InvestmentMemoRecord>())
    }
}
