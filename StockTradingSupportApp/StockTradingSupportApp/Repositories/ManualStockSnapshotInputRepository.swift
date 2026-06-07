//
//  ManualStockSnapshotInputRepository.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

protocol ManualStockSnapshotInputRepository: AnyObject {
    func fetchInput(stockCode: String) -> ManualStockSnapshotInput?
    @discardableResult func save(_ input: ManualStockSnapshotInput) throws -> ManualStockSnapshotInput
    @discardableResult func delete(stockCode: String) -> Bool
}

enum ManualStockSnapshotInputRepositoryError: Error, Equatable {
    case persistenceFailure(String)
}

final class InMemoryManualStockSnapshotInputRepository: ManualStockSnapshotInputRepository {
    private var inputsByStockCode: [String: ManualStockSnapshotInput]

    init(initialInputs: [ManualStockSnapshotInput] = []) {
        self.inputsByStockCode = Dictionary(
            uniqueKeysWithValues: initialInputs.map { input in
                (input.stockCode, input)
            }
        )
    }

    func fetchInput(stockCode: String) -> ManualStockSnapshotInput? {
        inputsByStockCode[stockCode]
    }

    @discardableResult
    func save(_ input: ManualStockSnapshotInput) throws -> ManualStockSnapshotInput {
        inputsByStockCode[input.stockCode] = input
        return input
    }

    @discardableResult
    func delete(stockCode: String) -> Bool {
        inputsByStockCode.removeValue(forKey: stockCode) != nil
    }
}
