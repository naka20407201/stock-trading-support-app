//
//  LocalStockMasterProvider.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

protocol StockMasterProviding {
    func loadSeedFile() throws -> StockMasterSeedFile
}

struct LocalStockMasterProvider: StockMasterProviding {
    private let bundle: Bundle
    private let resourceName: String

    init(bundle: Bundle = .main, resourceName: String = "nikkei225_mock_stocks") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    func loadSeedFile() throws -> StockMasterSeedFile {
        guard let url = resourceURL() else {
            throw LocalStockMasterProviderError.resourceNotFound(resourceName: resourceName)
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(StockMasterSeedFile.self, from: data)
        } catch let error as DecodingError {
            throw LocalStockMasterProviderError.decodingFailed(error)
        } catch {
            throw LocalStockMasterProviderError.loadingFailed(error)
        }
    }

    private func resourceURL() -> URL? {
        bundle.url(forResource: resourceName, withExtension: "json")
            ?? bundle.url(forResource: resourceName, withExtension: "json", subdirectory: "Resources")
    }
}

enum LocalStockMasterProviderError: LocalizedError {
    case resourceNotFound(resourceName: String)
    case decodingFailed(DecodingError)
    case loadingFailed(Error)

    var errorDescription: String? {
        switch self {
        case let .resourceNotFound(resourceName):
            return "\(resourceName).json がアプリ内に見つかりません。"
        case let .decodingFailed(error):
            return "銘柄候補JSONの形式を確認できませんでした: \(error.localizedDescription)"
        case let .loadingFailed(error):
            return "銘柄候補JSONの読み込みに失敗しました: \(error.localizedDescription)"
        }
    }
}
