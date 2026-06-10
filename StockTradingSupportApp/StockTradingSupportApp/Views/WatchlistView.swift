//
//  WatchlistView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct WatchlistView: View {
    @ObservedObject var viewModel: WatchlistViewModel
    let investmentMemoRepository: any InvestmentMemoRepository
    let alertRuleRepository: any AlertRuleRepository
    let stockDataProvider: any StockDataProviding
    let alertMatchHistoryRepository: any AlertMatchHistoryRepository
    let manualStockSnapshotInputRepository: any ManualStockSnapshotInputRepository

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            if viewModel.items.isEmpty && viewModel.errorMessage == nil {
                ContentUnavailableView(
                    "ウォッチリストは未登録です",
                    systemImage: "list.bullet.rectangle",
                    description: Text("右上の追加ボタンから銘柄を追加できます。")
                )
            } else if !viewModel.items.isEmpty {
                Section("ウォッチリスト") {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            StockDetailView(
                                watchlistItem: item,
                                memoRepository: investmentMemoRepository,
                                alertRuleRepository: alertRuleRepository,
                                stockDataProvider: stockDataProvider,
                                alertMatchHistoryRepository: alertMatchHistoryRepository,
                                manualStockSnapshotInputRepository: manualStockSnapshotInputRepository
                            )
                        } label: {
                            WatchlistItemRow(item: item)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }

            Section("今後の機能") {
                Label("確認メモは銘柄詳細で記録できます", systemImage: "note.text")
                Label("ユーザー設定条件は銘柄詳細で登録できます", systemImage: "slider.horizontal.3")
                Label("条件一致履歴は銘柄詳細で確認できます", systemImage: "clock.arrow.circlepath")
            }
        }
        .navigationTitle("ウォッチリスト")
        .toolbar {
            NavigationLink {
                AddStockView(viewModel: viewModel)
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("ウォッチリストに銘柄を追加")
        }
        .onAppear(perform: viewModel.refresh)
    }

    private func deleteItems(at offsets: IndexSet) {
        let idsToDelete = offsets.map { viewModel.items[$0].id }

        for id in idsToDelete {
            viewModel.delete(id: id)
        }
    }
}

private struct WatchlistItemRow: View {
    let item: WatchlistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.headline)

            HStack(spacing: 10) {
                Label(item.code, systemImage: "number")
                Text(item.market)
                Text(item.industry)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        WatchlistView(
            viewModel: WatchlistViewModel(),
            investmentMemoRepository: InMemoryInvestmentMemoRepository(),
            alertRuleRepository: InMemoryAlertRuleRepository(),
            stockDataProvider: MockStockDataProvider(),
            alertMatchHistoryRepository: InMemoryAlertMatchHistoryRepository(),
            manualStockSnapshotInputRepository: InMemoryManualStockSnapshotInputRepository()
        )
    }
}
