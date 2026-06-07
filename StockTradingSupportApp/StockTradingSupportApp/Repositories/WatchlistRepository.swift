//
//  WatchlistRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

protocol WatchlistRepository: AnyObject {
    func fetchItems() -> [WatchlistItem]
    func contains(code: String) -> Bool
    @discardableResult func add(_ item: WatchlistItem) throws -> WatchlistItem
    @discardableResult func delete(id: WatchlistItem.ID) -> Bool
}

enum WatchlistRepositoryError: Error, Equatable {
    case duplicateCode(String)
    case persistenceFailure(String)
}

final class InMemoryWatchlistRepository: WatchlistRepository {
    private var items: [WatchlistItem]

    init(initialItems: [WatchlistItem] = []) {
        self.items = initialItems
    }

    func fetchItems() -> [WatchlistItem] {
        items
    }

    func contains(code: String) -> Bool {
        items.contains { $0.code == code }
    }

    @discardableResult
    func add(_ item: WatchlistItem) throws -> WatchlistItem {
        guard !contains(code: item.code) else {
            throw WatchlistRepositoryError.duplicateCode(item.code)
        }

        items.append(item)
        return item
    }

    @discardableResult
    func delete(id: WatchlistItem.ID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return false
        }

        items.remove(at: index)
        return true
    }
}

extension InMemoryWatchlistRepository {
    static func sample() -> InMemoryWatchlistRepository {
        InMemoryWatchlistRepository(initialItems: [
            WatchlistItem(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                code: "7203",
                name: "トヨタ自動車",
                market: "TSE Prime",
                industry: "輸送用機器",
                isNikkei225: true,
                createdAt: Date(timeIntervalSince1970: 0)
            ),
            WatchlistItem(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                code: "6758",
                name: "ソニーグループ",
                market: "TSE Prime",
                industry: "電気機器",
                isNikkei225: true,
                createdAt: Date(timeIntervalSince1970: 1)
            ),
            WatchlistItem(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                code: "9432",
                name: "日本電信電話",
                market: "TSE Prime",
                industry: "情報・通信業",
                isNikkei225: true,
                createdAt: Date(timeIntervalSince1970: 2)
            )
        ])
    }
}
