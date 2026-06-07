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

final class SwiftDataAlertMatchHistoryRepository: AlertMatchHistoryRepository {
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

    func fetchHistories(stockCode: String) -> [AlertMatchHistory] {
        do {
            return try fetchRecords()
                .filter { $0.stockCode == stockCode }
                .compactMap(\.domainModel)
                .sorted { $0.matchedAt > $1.matchedAt }
        } catch {
            // TODO: Surface persistence read failures through ViewModel state instead of showing an empty list.
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

    func deleteAll(stockCode: String) {
        do {
            let records = try fetchRecords().filter { $0.stockCode == stockCode }
            for record in records {
                modelContext.delete(record)
            }

            try modelContext.save()
        } catch {
            modelContext.rollback()
        }
    }

    private func fetchRecords() throws -> [AlertMatchHistoryRecord] {
        try modelContext.fetch(FetchDescriptor<AlertMatchHistoryRecord>())
    }
}
