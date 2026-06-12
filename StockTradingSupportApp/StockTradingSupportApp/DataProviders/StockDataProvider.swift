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

protocol ApiKeyProviding {
    var apiKey: String? { get }
}

struct EnvironmentApiKeyProvider: ApiKeyProviding {
    private let environmentKey: String
    private let environment: [String: String]

    init(
        environmentKey: String,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.environmentKey = environmentKey
        self.environment = environment
    }

    var apiKey: String? {
        environment[environmentKey]
    }
}

struct StaticApiKeyProvider: ApiKeyProviding {
    let apiKey: String?

    init(apiKey: String?) {
        self.apiKey = apiKey
    }
}

struct ExternalApiConfiguration {
    let baseURL: URL
    let apiKeyProvider: any ApiKeyProviding
}

struct JQuantsApiConfiguration {
    static let apiKeyEnvironmentName = "JQUANTS_API_KEY"
    static let defaultBaseURL = URL(string: "https://api.jquants.com")!

    let baseURL: URL
    let apiKeyProvider: any ApiKeyProviding

    init(
        baseURL: URL = Self.defaultBaseURL,
        apiKeyProvider: any ApiKeyProviding = EnvironmentApiKeyProvider(
            environmentKey: Self.apiKeyEnvironmentName
        )
    ) {
        self.baseURL = baseURL
        self.apiKeyProvider = apiKeyProvider
    }

    var apiKey: String? {
        apiKeyProvider.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct HTTPResponse: Equatable {
    let statusCode: Int
    let data: Data
    let headers: [String: String]

    init(
        statusCode: Int,
        data: Data = Data(),
        headers: [String: String] = [:]
    ) {
        self.statusCode = statusCode
        self.data = data
        self.headers = headers
    }
}

enum HTTPClientError: Error, Equatable {
    case notImplemented
    case transport(String)
    case invalidResponse

    var externalDataMessage: String {
        switch self {
        case .notImplemented:
            return "HTTP通信は未実装です"
        case .transport(let message):
            return message
        case .invalidResponse:
            return "HTTPレスポンスを確認できませんでした"
        }
    }
}

protocol HTTPClient {
    func send(_ request: URLRequest) -> Result<HTTPResponse, HTTPClientError>
}

struct URLSessionHTTPClient: HTTPClient {
    func send(_ request: URLRequest) -> Result<HTTPResponse, HTTPClientError> {
        .failure(.notImplemented)
    }
}

enum JQuantsEndpoint {
    case stockSnapshot(stockCode: String)

    var path: String {
        switch self {
        case .stockSnapshot:
            return "/v1/stock-snapshot-placeholder"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .stockSnapshot(let stockCode):
            return [URLQueryItem(name: "code", value: stockCode)]
        }
    }
}

struct JQuantsRequestBuilder {
    let configuration: JQuantsApiConfiguration

    init(configuration: JQuantsApiConfiguration) {
        self.configuration = configuration
    }

    func request(for endpoint: JQuantsEndpoint) -> URLRequest? {
        let endpointURL = configuration.baseURL.appendingPathComponent(endpoint.path)
        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = endpoint.queryItems

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let apiKey = configuration.apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
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

protocol ExternalStockDataClient {
    func latestSnapshotResponse(for stockCode: String) -> Result<ExternalStockSnapshotResponse?, ExternalStockDataProviderError>
}

struct JQuantsDailyQuoteResponse: Equatable {
    let stockCode: String
    let close: Double?
    let volume: Double?
    let capturedAt: Date?
}

extension JQuantsDailyQuoteResponse: Decodable {}

struct JQuantsFinancialMetricsResponse: Equatable, Decodable {
    let stockCode: String
    let per: Double?
    let pbr: Double?
}

struct JQuantsStockDataMapper {
    func map(
        dailyQuote: JQuantsDailyQuoteResponse?,
        financialMetrics: JQuantsFinancialMetricsResponse?,
        sourceName: String = "J-Quants"
    ) -> ExternalStockSnapshotResponse? {
        let dailyQuoteStockCode = dailyQuote?.stockCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let financialMetricsStockCode = financialMetrics?.stockCode.trimmingCharacters(in: .whitespacesAndNewlines)

        if let dailyQuoteStockCode,
           let financialMetricsStockCode,
           !dailyQuoteStockCode.isEmpty,
           !financialMetricsStockCode.isEmpty,
           dailyQuoteStockCode != financialMetricsStockCode {
            return nil
        }

        let stockCode = dailyQuoteStockCode ?? financialMetricsStockCode ?? ""
        guard !stockCode.isEmpty else {
            return nil
        }

        return ExternalStockSnapshotResponse(
            stockCode: stockCode,
            currentPrice: dailyQuote?.close,
            per: financialMetrics?.per,
            pbr: financialMetrics?.pbr,
            volume: dailyQuote?.volume,
            capturedAt: dailyQuote?.capturedAt,
            sourceName: sourceName
        )
    }
}

struct JQuantsStockDataClient: ExternalStockDataClient {
    private struct SnapshotPayload: Decodable {
        let dailyQuote: JQuantsDailyQuoteResponse?
        let financialMetrics: JQuantsFinancialMetricsResponse?
    }

    private let configuration: JQuantsApiConfiguration
    private let httpClient: any HTTPClient
    private let requestBuilder: JQuantsRequestBuilder
    private let mapper: JQuantsStockDataMapper
    private let decoder: JSONDecoder

    init(
        configuration: JQuantsApiConfiguration,
        httpClient: any HTTPClient = URLSessionHTTPClient(),
        mapper: JQuantsStockDataMapper = JQuantsStockDataMapper(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.configuration = configuration
        self.httpClient = httpClient
        self.requestBuilder = JQuantsRequestBuilder(configuration: configuration)
        self.mapper = mapper
        self.decoder = decoder
    }

    init(
        apiKey: String? = nil,
        httpClient: any HTTPClient = URLSessionHTTPClient(),
        mapper: JQuantsStockDataMapper = JQuantsStockDataMapper(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.init(
            configuration: JQuantsApiConfiguration(
                apiKeyProvider: StaticApiKeyProvider(apiKey: apiKey)
            ),
            httpClient: httpClient,
            mapper: mapper,
            decoder: decoder
        )
    }

    func latestSnapshotResponse(for stockCode: String) -> Result<ExternalStockSnapshotResponse?, ExternalStockDataProviderError> {
        guard configuration.apiKey?.isEmpty == false else {
            return .failure(.apiKeyNotConfigured)
        }

        let normalizedStockCode = stockCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedStockCode.isEmpty else {
            return .success(nil)
        }

        guard let request = requestBuilder.request(for: .stockSnapshot(stockCode: normalizedStockCode)) else {
            return .failure(.fetchFailed("J-Quantsリクエストを作成できませんでした"))
        }

        switch httpClient.send(request) {
        case .success(let response):
            guard response.statusCode != 429 else {
                return .failure(.rateLimited)
            }

            guard (200..<300).contains(response.statusCode) else {
                return .failure(.fetchFailed("HTTPステータス \(response.statusCode)"))
            }

            do {
                let payload = try decoder.decode(SnapshotPayload.self, from: response.data)
                return .success(
                    mapper.map(
                        dailyQuote: payload.dailyQuote,
                        financialMetrics: payload.financialMetrics
                    )
                )
            } catch {
                return .failure(.fetchFailed("J-Quantsレスポンスを解析できませんでした"))
            }
        case .failure(let error):
            return .failure(.fetchFailed(error.externalDataMessage))
        }
    }
}

final class StubExternalStockDataProvider: ExternalStockDataProviding {
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

final class ExternalApiStockDataProvider: ExternalStockDataProviding {
    private let client: any ExternalStockDataClient
    private let currentDate: () -> Date
    private(set) var lastError: ExternalStockDataProviderError?

    init(
        client: any ExternalStockDataClient = JQuantsStockDataClient(),
        currentDate: @escaping () -> Date = Date.init
    ) {
        self.client = client
        self.currentDate = currentDate
    }

    func snapshot(for stockCode: String) -> StockSnapshot? {
        switch client.latestSnapshotResponse(for: stockCode) {
        case .success(let response):
            guard let response else {
                lastError = nil
                return nil
            }

            guard let snapshot = response.stockSnapshot(capturedAt: currentDate()) else {
                lastError = .missingRequiredValues
                return nil
            }

            lastError = nil
            return snapshot
        case .failure(let error):
            lastError = error
            return nil
        }
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
