//
//  WatchlistView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct WatchlistView: View {
    var body: some View {
        List {
            Section("ウォッチリスト") {
                ContentUnavailableView(
                    "現在は初期画面です",
                    systemImage: "list.bullet.rectangle",
                    description: Text("日経225モック銘柄マスタとウォッチリスト保存機能は次の開発ステップで追加します。")
                )
            }

            Section("今後の表示項目") {
                NavigationLink {
                    StockDetailView()
                } label: {
                    Label("銘柄詳細", systemImage: "doc.text")
                }

                Label("ユーザー設定条件", systemImage: "slider.horizontal.3")
                Label("条件履歴", systemImage: "clock.arrow.circlepath")
            }
        }
        .navigationTitle("ウォッチリスト")
    }
}

#Preview {
    NavigationStack {
        WatchlistView()
    }
}
