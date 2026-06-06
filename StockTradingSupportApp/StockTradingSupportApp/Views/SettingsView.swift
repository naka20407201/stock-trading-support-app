//
//  SettingsView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("設定") {
                Text("現在は初期画面です")
                Text("通知設定、モックデータ管理、データリセットなどの置き場所として利用します。")
                    .foregroundStyle(.secondary)
            }

            Section("初期版の前提") {
                Label("SwiftData利用前提の構成です", systemImage: "externaldrive")
                Label("外部API・リアルタイム株価取得は未実装です", systemImage: "wifi.slash")
                Label("自動売買・証券口座連携は実装しません", systemImage: "lock")
            }
        }
        .navigationTitle("設定")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
