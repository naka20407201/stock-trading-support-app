//
//  StockDetailView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct StockDetailView: View {
    let watchlistItem: WatchlistItem?

    init(watchlistItem: WatchlistItem? = nil) {
        self.watchlistItem = watchlistItem
    }

    var body: some View {
        List {
            if let watchlistItem {
                Section("ユーザーが確認する銘柄情報") {
                    LabeledContent("銘柄名", value: watchlistItem.name)
                    LabeledContent("銘柄コード", value: watchlistItem.code)
                    LabeledContent("市場区分", value: watchlistItem.market)
                    LabeledContent("業種", value: watchlistItem.industry)
                    LabeledContent("日経225標準候補", value: watchlistItem.isNikkei225 ? "はい" : "いいえ")
                }
            } else {
                Section("銘柄詳細") {
                    Text("現在は初期画面です")
                    Text("ウォッチリストから遷移した場合、銘柄名と銘柄コードを表示します。")
                        .foregroundStyle(.secondary)
                }
            }

            Section("投資メモ") {
                Label("メモは今後実装します", systemImage: "note.text")
            }

            Section("ユーザー設定条件") {
                Label("条件設定は今後実装します", systemImage: "slider.horizontal.3")
                Label("条件履歴は今後実装します", systemImage: "clock.arrow.circlepath")
            }
        }
        .navigationTitle(watchlistItem?.name ?? "銘柄詳細")
    }
}

#Preview {
    NavigationStack {
        StockDetailView(
            watchlistItem: WatchlistItem(
                code: "7203",
                name: "トヨタ自動車",
                market: "TSE Prime",
                industry: "輸送用機器",
                isNikkei225: true
            )
        )
    }
}
