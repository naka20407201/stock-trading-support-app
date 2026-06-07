//
//  WatchlistViewModel.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Combine
import Foundation

final class WatchlistViewModel: ObservableObject {
    @Published private(set) var items: [WatchlistItem] = []

    private let repository: any WatchlistRepository

    init(repository: any WatchlistRepository = InMemoryWatchlistRepository.sample()) {
        self.repository = repository
        refresh()
    }

    func refresh() {
        items = repository.fetchItems()
    }

    @discardableResult
    func add(_ item: WatchlistItem) throws -> WatchlistItem {
        let addedItem = try repository.add(item)
        refresh()
        return addedItem
    }

    func delete(id: WatchlistItem.ID) {
        _ = repository.delete(id: id)
        refresh()
    }

    func contains(code: String) -> Bool {
        repository.contains(code: code)
    }
}
