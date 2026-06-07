//
//  SwiftDataInvestmentMemoRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation
import SwiftData

final class SwiftDataInvestmentMemoRepository: InvestmentMemoRepository, RepositoryReadStatusProviding {
    // The container is retained to keep in-memory test stores alive for the repository lifetime.
    private let modelContainer: ModelContainer?
    private let modelContext: ModelContext
    private(set) var readErrorMessage: String?

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
            readErrorMessage = nil
            return try fetchRecords(stockCode: stockCode).map(\.domainModel)
        } catch {
            readErrorMessage = RepositoryStatusMessage.readFailed
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
            guard let record = try fetchRecord(id: memo.id) else {
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
            guard let record = try fetchRecord(id: id) else {
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

    private func fetchRecords(stockCode: String) throws -> [InvestmentMemoRecord] {
        let targetStockCode = stockCode
        let descriptor = FetchDescriptor<InvestmentMemoRecord>(
            predicate: #Predicate { record in
                record.stockCode == targetStockCode
            },
            sortBy: [
                SortDescriptor(\.updatedAt, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchRecord(id: InvestmentMemo.ID) throws -> InvestmentMemoRecord? {
        let targetID = id
        var descriptor = FetchDescriptor<InvestmentMemoRecord>(
            predicate: #Predicate { record in
                record.id == targetID
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
