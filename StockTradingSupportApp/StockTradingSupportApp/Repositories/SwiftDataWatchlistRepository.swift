//
//  SwiftDataWatchlistRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation
import SwiftData

final class SwiftDataWatchlistRepository: WatchlistRepository, RepositoryReadStatusProviding {
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

    func fetchItems() -> [WatchlistItem] {
        do {
            readErrorMessage = nil
            return try fetchRecords().map(\.domainModel)
        } catch {
            readErrorMessage = RepositoryStatusMessage.readFailed
            return []
        }
    }

    func contains(code: String) -> Bool {
        do {
            readErrorMessage = nil
            return try fetchRecord(code: code) != nil
        } catch {
            readErrorMessage = RepositoryStatusMessage.readFailed
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

    private func fetchRecords() throws -> [WatchlistItemRecord] {
        let descriptor = FetchDescriptor<WatchlistItemRecord>(
            sortBy: [
                SortDescriptor(\.createdAt, order: .forward),
                SortDescriptor(\.code, order: .forward)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchRecord(code: String) throws -> WatchlistItemRecord? {
        let targetCode = code
        var descriptor = FetchDescriptor<WatchlistItemRecord>(
            predicate: #Predicate { record in
                record.code == targetCode
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchRecord(id: WatchlistItem.ID) throws -> WatchlistItemRecord? {
        let targetID = id
        var descriptor = FetchDescriptor<WatchlistItemRecord>(
            predicate: #Predicate { record in
                record.id == targetID
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
