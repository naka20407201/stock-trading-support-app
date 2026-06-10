//
//  StockDataProvider.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

protocol StockDataProviding {
    func snapshot(for stockCode: String) -> StockSnapshot?
}

struct ManualInputStockDataProvider: StockDataProviding {
    private let repository: any ManualStockSnapshotInputRepository

    init(repository: any ManualStockSnapshotInputRepository) {
        self.repository = repository
    }

    func snapshot(for stockCode: String) -> StockSnapshot? {
        guard let input = repository.fetchInput(stockCode: stockCode), input.hasAnyValue else {
            return nil
        }

        return input.stockSnapshot
    }
}

enum ExternalStockDataProviderError: Error, Equatable {
    case notImplemented
    case apiKeyNotConfigured
    case rateLimited
    case fetchFailed(String)
    case missingRequiredValues
}

struct ExternalStockSnapshotResponse: Equatable {
    let stockCode: String
    let currentPrice: Double?
    let per: Double?
    let pbr: Double?
    let volume: Double?
    let capturedAt: Date?
    let sourceName: String?

    init(
        stockCode: String,
        currentPrice: Double? = nil,
        per: Double? = nil,
        pbr: Double? = nil,
        volume: Double? = nil,
        capturedAt: Date? = nil,
        sourceName: String? = nil
    ) {
        self.stockCode = stockCode
        self.currentPrice = currentPrice
        self.per = per
        self.pbr = pbr
        self.volume = volume
        self.capturedAt = capturedAt
        self.sourceName = sourceName
    }

    var hasAnyMetricValue: Bool {
        currentPrice != nil || per != nil || pbr != nil || volume != nil
    }

    func stockSnapshot(capturedAt fallbackCapturedAt: Date = Date()) -> StockSnapshot? {
        let normalizedStockCode = stockCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedStockCode.isEmpty, hasAnyMetricValue else {
            return nil
        }

        let normalizedSourceName = sourceName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let snapshotSourceName: String
        if let normalizedSourceName, !normalizedSourceName.isEmpty {
            snapshotSourceName = normalizedSourceName
        } else {
            snapshotSourceName = "外部API疑似データ"
        }

        return StockSnapshot(
            stockCode: normalizedStockCode,
            currentPrice: currentPrice,
            per: per,
            pbr: pbr,
            volume: volume,
            capturedAt: capturedAt ?? fallbackCapturedAt,
            sourceName: snapshotSourceName
        )
    }
}

protocol ExternalStockDataProviding: StockDataProviding {
    var lastError: ExternalStockDataProviderError? { get }
}

final class ExternalApiStockDataProvider: ExternalStockDataProviding {
    private let responsesByStockCode: [String: ExternalStockSnapshotResponse]
    private let currentDate: () -> Date
    private(set) var lastError: ExternalStockDataProviderError?

    init(
        responses: [String: ExternalStockSnapshotResponse] = [:],
        currentDate: @escaping () -> Date = Date.init
    ) {
        self.responsesByStockCode = responses
        self.currentDate = currentDate
    }

    init(
        responses: [ExternalStockSnapshotResponse],
        currentDate: @escaping () -> Date = Date.init
    ) {
        self.responsesByStockCode = Dictionary(
            uniqueKeysWithValues: responses.map { response in
                (response.stockCode, response)
            }
        )
        self.currentDate = currentDate
    }

    func snapshot(for stockCode: String) -> StockSnapshot? {
        guard let response = responsesByStockCode[stockCode] else {
            lastError = nil
            return nil
        }

        guard let snapshot = response.stockSnapshot(capturedAt: currentDate()) else {
            lastError = .missingRequiredValues
            return nil
        }

        lastError = nil
        return snapshot
    }
}

struct CompositeStockDataProvider: StockDataProviding {
    private let providers: [any StockDataProviding]

    init(providers: [any StockDataProviding]) {
        self.providers = providers
    }

    func snapshot(for stockCode: String) -> StockSnapshot? {
        for provider in providers {
            if let snapshot = provider.snapshot(for: stockCode) {
                return snapshot
            }
        }

        return nil
    }
}

struct FallbackStockDataProvider: StockDataProviding {
    private let primaryProvider: any StockDataProviding
    private let fallbackProvider: any StockDataProviding

    init(
        primaryProvider: any StockDataProviding,
        fallbackProvider: any StockDataProviding
    ) {
        self.primaryProvider = primaryProvider
        self.fallbackProvider = fallbackProvider
    }

    func snapshot(for stockCode: String) -> StockSnapshot? {
        primaryProvider.snapshot(for: stockCode) ?? fallbackProvider.snapshot(for: stockCode)
    }
}

struct MockStockDataValue: Equatable {
    let currentPrice: Double?
    let per: Double?
    let pbr: Double?
    let volume: Double?

    init(
        currentPrice: Double? = nil,
        per: Double? = nil,
        pbr: Double? = nil,
        volume: Double? = nil
    ) {
        self.currentPrice = currentPrice
        self.per = per
        self.pbr = pbr
        self.volume = volume
    }
}

struct MockStockDataProvider: StockDataProviding {
    private let sourceName: String
    private let fixedCapturedAt: Date?
    private let mockValues: [String: MockStockDataValue]

    init(
        sourceName: String = "固定モック株価",
        capturedAt: Date? = nil,
        mockValues: [String: MockStockDataValue] = [
            "7203": MockStockDataValue(currentPrice: 3200, per: 12.5, pbr: 1.1, volume: 2_500_000),
            "6758": MockStockDataValue(currentPrice: 14500, per: 18.2, pbr: 2.3, volume: 1_800_000),
            "9984": MockStockDataValue(currentPrice: 8600, per: 24.0, pbr: 1.4, volume: 12_000_000),
            "8035": MockStockDataValue(currentPrice: 35000, per: 32.5, pbr: 8.1, volume: 900_000),
            "9432": MockStockDataValue(currentPrice: 155, per: 11.0, pbr: 1.5, volume: 95_000_000)
        ]
    ) {
        self.sourceName = sourceName
        self.fixedCapturedAt = capturedAt
        self.mockValues = mockValues
    }

    init(
        sourceName: String = "固定モック株価",
        capturedAt: Date? = nil,
        mockValues: [String: Double]
    ) {
        self.init(
            sourceName: sourceName,
            capturedAt: capturedAt,
            mockValues: mockValues.mapValues { currentPrice in
                MockStockDataValue(currentPrice: currentPrice)
            }
        )
    }

    func snapshot(for stockCode: String) -> StockSnapshot? {
        guard let mockValue = mockValues[stockCode] else {
            return nil
        }

        return StockSnapshot(
            stockCode: stockCode,
            currentPrice: mockValue.currentPrice,
            per: mockValue.per,
            pbr: mockValue.pbr,
            volume: mockValue.volume,
            capturedAt: fixedCapturedAt ?? Date(),
            sourceName: sourceName
        )
    }
}
