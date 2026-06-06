//
//  StockDetailView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct StockDetailView: View {
    var body: some View {
        List {
            Section("銘柄詳細") {
                Text("現在は初期画面です")
                Text("銘柄コード、銘柄名、市場区分、業種などは今後追加します。")
                    .foregroundStyle(.secondary)
            }

            Section("投資メモ") {
                Label("ユーザー自身の確認メモを保存する予定です", systemImage: "note.text")
            }

            Section("アラート") {
                Label("ユーザー設定条件", systemImage: "slider.horizontal.3")
                Label("条件履歴", systemImage: "clock.arrow.circlepath")
            }
        }
        .navigationTitle("銘柄詳細")
    }
}

#Preview {
    NavigationStack {
        StockDetailView()
    }
}
