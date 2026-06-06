//
//  StockSearchView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct StockSearchView: View {
    var body: some View {
        List {
            Section("銘柄を追加") {
                ContentUnavailableView(
                    "現在は初期画面です",
                    systemImage: "magnifyingglass",
                    description: Text("日経225銘柄候補の検索と任意銘柄の手入力追加は、今後のステップで実装します。")
                )
            }

            Section("データ取得") {
                Label("外部API・リアルタイム株価取得は未実装です", systemImage: "wifi.slash")
                Label("初期版では手入力値またはモックデータを利用します", systemImage: "square.and.pencil")
            }
        }
        .navigationTitle("銘柄を追加")
    }
}

#Preview {
    NavigationStack {
        StockSearchView()
    }
}
