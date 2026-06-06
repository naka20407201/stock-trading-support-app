//
//  WatchlistView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct WatchlistView: View {
    private let repository: any WatchlistRepository

    @State private var items: [WatchlistItem]

    init(repository: any WatchlistRepository = InMemoryWatchlistRepository.sample()) {
        self.repository = repository
        _items = State(initialValue: repository.fetchItems())
    }

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView(
                    "ウォッチリストは未登録です",
                    systemImage: "list.bullet.rectangle",
                    description: Text("日経225候補からの追加と任意銘柄追加は、今後のステップで実装します。")
                )
            } else {
                Section("ウォッチリスト") {
                    ForEach(items) { item in
                        NavigationLink {
                            StockDetailView(watchlistItem: item)
                        } label: {
                            WatchlistItemRow(item: item)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }

            Section("今後の機能") {
                Label("投資メモは今後実装します", systemImage: "note.text")
                Label("ユーザー設定条件は今後実装します", systemImage: "slider.horizontal.3")
                Label("条件履歴は今後実装します", systemImage: "clock.arrow.circlepath")
            }
        }
        .navigationTitle("ウォッチリスト")
        .onAppear(perform: refreshItems)
    }

    private func refreshItems() {
        items = repository.fetchItems()
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            _ = repository.delete(id: item.id)
        }

        refreshItems()
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
        WatchlistView()
    }
}
