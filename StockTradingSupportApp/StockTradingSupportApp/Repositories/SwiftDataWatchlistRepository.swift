//
//  SwiftDataWatchlistRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation
import SwiftData

final class SwiftDataWatchlistRepository: WatchlistRepository {
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

    func fetchItems() -> [WatchlistItem] {
        do {
            return try fetchRecords()
                .map(\.domainModel)
                .sorted { lhs, rhs in
                    if lhs.createdAt == rhs.createdAt {
                        return lhs.code < rhs.code
                    }

                    return lhs.createdAt < rhs.createdAt
                }
        } catch {
            return []
        }
    }

    func contains(code: String) -> Bool {
        do {
            return try fetchRecords().contains { $0.code == code }
        } catch {
            return false
        }
    }

    @discardableResult
    func add(_ item: WatchlistItem) throws -> WatchlistItem {
        guard !contains(code: item.code) else {
            throw WatchlistRepositoryError.duplicateCode(item.code)
        }

        let record = WatchlistItemRecord(item: item)
        modelContext.insert(record)

        do {
            try modelContext.save()
            return item
        } catch {
            modelContext.rollback()
            throw WatchlistRepositoryError.persistenceFailure(error.localizedDescription)
        }
    }

    @discardableResult
    func delete(id: WatchlistItem.ID) -> Bool {
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

    private func fetchRecords() throws -> [WatchlistItemRecord] {
        try modelContext.fetch(FetchDescriptor<WatchlistItemRecord>())
    }
}
