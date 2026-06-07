//
//  RootView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct RootView: View {
    @StateObject private var watchlistViewModel: WatchlistViewModel
    private let investmentMemoRepository: any InvestmentMemoRepository
    private let alertRuleRepository: any AlertRuleRepository
    private let stockDataProvider: any StockDataProviding
    private let alertMatchHistoryRepository: any AlertMatchHistoryRepository

    init(
        watchlistViewModel: WatchlistViewModel = WatchlistViewModel(),
        investmentMemoRepository: any InvestmentMemoRepository = InMemoryInvestmentMemoRepository(),
        alertRuleRepository: any AlertRuleRepository = InMemoryAlertRuleRepository(),
        stockDataProvider: any StockDataProviding = MockStockDataProvider(),
        alertMatchHistoryRepository: any AlertMatchHistoryRepository = InMemoryAlertMatchHistoryRepository()
    ) {
        _watchlistViewModel = StateObject(wrappedValue: watchlistViewModel)
        self.investmentMemoRepository = investmentMemoRepository
        self.alertRuleRepository = alertRuleRepository
        self.stockDataProvider = stockDataProvider
        self.alertMatchHistoryRepository = alertMatchHistoryRepository
    }

    var body: some View {
        TabView {
            NavigationStack {
                WatchlistView(
                    viewModel: watchlistViewModel,
                    investmentMemoRepository: investmentMemoRepository,
                    alertRuleRepository: alertRuleRepository,
                    stockDataProvider: stockDataProvider,
                    alertMatchHistoryRepository: alertMatchHistoryRepository
                )
            }
            .tabItem {
                Label("ウォッチリスト", systemImage: "list.bullet")
            }

            NavigationStack {
                AddStockView(viewModel: watchlistViewModel)
            }
            .tabItem {
                Label("銘柄を追加", systemImage: "plus.magnifyingglass")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    RootView()
}
