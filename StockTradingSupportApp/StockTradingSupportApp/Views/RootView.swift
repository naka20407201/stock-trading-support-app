//
//  RootView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct RootView: View {
    @StateObject private var watchlistViewModel = WatchlistViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                WatchlistView(viewModel: watchlistViewModel)
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
