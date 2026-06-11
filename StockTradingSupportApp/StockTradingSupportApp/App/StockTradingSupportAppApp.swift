//
//  StockTradingSupportAppApp.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftData
import SwiftUI

@main
struct StockTradingSupportAppApp: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PersistenceSchemaPlaceholder.self,
            WatchlistItemRecord.self,
            InvestmentMemoRecord.self,
            AlertRuleRecord.self,
            AlertMatchHistoryRecord.self,
            ManualStockSnapshotInputRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            let manualStockSnapshotInputRepository = SwiftDataManualStockSnapshotInputRepository(
                modelContainer: sharedModelContainer
            )
            let stockDataProvider = CompositeStockDataProvider(providers: [
                ManualInputStockDataProvider(
                    repository: manualStockSnapshotInputRepository
                ),
                MockStockDataProvider()
            ])

            RootView(
                watchlistViewModel: WatchlistViewModel(
                    repository: SwiftDataWatchlistRepository(
                        modelContainer: sharedModelContainer
                    )
                ),
                investmentMemoRepository: SwiftDataInvestmentMemoRepository(
                    modelContainer: sharedModelContainer
                ),
                alertRuleRepository: SwiftDataAlertRuleRepository(
                    modelContainer: sharedModelContainer
                ),
                stockDataProvider: stockDataProvider,
                alertMatchHistoryRepository: SwiftDataAlertMatchHistoryRepository(
                    modelContainer: sharedModelContainer
                ),
                manualStockSnapshotInputRepository: manualStockSnapshotInputRepository
            )
        }
        .modelContainer(sharedModelContainer)
    }
}
