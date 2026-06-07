//
//  AlertMatchHistoryRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

protocol AlertMatchHistoryRepository: AnyObject {
    func fetchHistories(stockCode: String) -> [AlertMatchHistory]
    @discardableResult func add(_ history: AlertMatchHistory) throws -> AlertMatchHistory
    @discardableResult func delete(id: AlertMatchHistory.ID) -> Bool
    func deleteAll(stockCode: String)
}

final class InMemoryAlertMatchHistoryRepository: AlertMatchHistoryRepository {
    private var histories: [AlertMatchHistory]

    init(initialHistories: [AlertMatchHistory] = []) {
        self.histories = initialHistories
    }

    func fetchHistories(stockCode: String) -> [AlertMatchHistory] {
        histories
            .filter { $0.stockCode == stockCode }
            .sorted { $0.matchedAt > $1.matchedAt }
    }

    @discardableResult
    func add(_ history: AlertMatchHistory) throws -> AlertMatchHistory {
        histories.append(history)
        return history
    }

    @discardableResult
    func delete(id: AlertMatchHistory.ID) -> Bool {
        guard let index = histories.firstIndex(where: { $0.id == id }) else {
            return false
        }

        histories.remove(at: index)
        return true
    }

    func deleteAll(stockCode: String) {
        histories.removeAll { $0.stockCode == stockCode }
    }
}
