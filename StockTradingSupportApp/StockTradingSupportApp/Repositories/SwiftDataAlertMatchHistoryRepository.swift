//
//  SwiftDataAlertMatchHistoryRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation
import SwiftData

enum AlertMatchHistoryRepositoryError: Error, Equatable {
    case persistenceFailure(String)
}

final class SwiftDataAlertMatchHistoryRepository: AlertMatchHistoryRepository, RepositoryReadStatusProviding {
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

    func fetchHistories(stockCode: String) -> [AlertMatchHistory] {
        do {
            readErrorMessage = nil
            return try fetchRecords(stockCode: stockCode).compactMap(\.domainModel)
        } catch {
            readErrorMessage = RepositoryStatusMessage.readFailed
            return []
        }
    }

    @discardableResult
    func add(_ history: AlertMatchHistory) throws -> AlertMatchHistory {
        let record = AlertMatchHistoryRecord(history: history)
        modelContext.insert(record)

        do {
            try modelContext.save()
            return history
        } catch {
            modelContext.rollback()
            throw AlertMatchHistoryRepositoryError.persistenceFailure(error.localizedDescription)
        }
    }

    @discardableResult
    func delete(id: AlertMatchHistory.ID) -> Bool {
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

    func deleteAll(stockCode: String) {
        do {
            let records = try fetchRecords(stockCode: stockCode)
            for record in records {
                modelContext.delete(record)
            }

            try modelContext.save()
        } catch {
            modelContext.rollback()
            // TODO: Consider changing AlertMatchHistoryRepository.deleteAll(stockCode:) to return Bool or throw.
        }
    }

    private func fetchRecords(stockCode: String) throws -> [AlertMatchHistoryRecord] {
        let targetStockCode = stockCode
        let descriptor = FetchDescriptor<AlertMatchHistoryRecord>(
            predicate: #Predicate { record in
                record.stockCode == targetStockCode
            },
            sortBy: [
                SortDescriptor(\.matchedAt, order: .reverse)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchRecord(id: AlertMatchHistory.ID) throws -> AlertMatchHistoryRecord? {
        let targetID = id
        var descriptor = FetchDescriptor<AlertMatchHistoryRecord>(
            predicate: #Predicate { record in
                record.id == targetID
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
