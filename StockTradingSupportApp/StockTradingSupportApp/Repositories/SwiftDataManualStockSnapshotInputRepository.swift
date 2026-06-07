//
//  SwiftDataManualStockSnapshotInputRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation
import SwiftData

final class SwiftDataManualStockSnapshotInputRepository: ManualStockSnapshotInputRepository, RepositoryReadStatusProviding {
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

    func fetchInput(stockCode: String) -> ManualStockSnapshotInput? {
        do {
            readErrorMessage = nil
            return try fetchRecord(stockCode: stockCode)?.domainModel
        } catch {
            readErrorMessage = RepositoryStatusMessage.readFailed
            return nil
        }
    }

    @discardableResult
    func save(_ input: ManualStockSnapshotInput) throws -> ManualStockSnapshotInput {
        do {
            if let record = try fetchRecord(stockCode: input.stockCode) {
                record.id = input.id
                record.currentPrice = input.currentPrice
                record.per = input.per
                record.pbr = input.pbr
                record.volume = input.volume
                record.updatedAt = input.updatedAt
                record.sourceName = input.sourceName
            } else {
                modelContext.insert(ManualStockSnapshotInputRecord(input: input))
            }

            try modelContext.save()
            return input
        } catch {
            modelContext.rollback()
            throw ManualStockSnapshotInputRepositoryError.persistenceFailure(error.localizedDescription)
        }
    }

    @discardableResult
    func delete(stockCode: String) -> Bool {
        do {
            guard let record = try fetchRecord(stockCode: stockCode) else {
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

    private func fetchRecord(stockCode: String) throws -> ManualStockSnapshotInputRecord? {
        let targetStockCode = stockCode
        var descriptor = FetchDescriptor<ManualStockSnapshotInputRecord>(
            predicate: #Predicate { record in
                record.stockCode == targetStockCode
            },
            sortBy: [
                SortDescriptor(\.updatedAt, order: .reverse)
            ]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
