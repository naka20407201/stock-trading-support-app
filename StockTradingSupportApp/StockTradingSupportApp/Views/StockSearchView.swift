//
//  StockSearchView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct StockSearchView: View {
    private let stockMasterProvider: any StockMasterProviding

    @State private var seedFile: StockMasterSeedFile?
    @State private var loadingErrorMessage: String?

    init(stockMasterProvider: any StockMasterProviding = LocalStockMasterProvider()) {
        self.stockMasterProvider = stockMasterProvider
    }

    var body: some View {
        List {
            if let seedFile {
                Section("日経225モック銘柄候補") {
                    if seedFile.stocks.isEmpty {
                        ContentUnavailableView(
                            "日経225モック銘柄候補が未登録です",
                            systemImage: "tray",
                            description: Text("外部API・リアルタイム株価取得は未実装です。")
                        )
                    } else {
                        ForEach(seedFile.stocks) { stock in
                            StockMasterSeedRow(stock: stock)
                        }
                    }
                }

                Section("固定モックデータ") {
                    LabeledContent("sourceName", value: seedFile.sourceName)
                    LabeledContent("asOfDate", value: seedFile.asOfDate)
                    Text("この銘柄候補はローカル開発用の固定モックデータです。最新の日経225採用銘柄を保証するものではありません。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else if let loadingErrorMessage {
                Section("日経225モック銘柄候補") {
                    ContentUnavailableView(
                        "銘柄候補を読み込めませんでした",
                        systemImage: "exclamationmark.triangle",
                        description: Text("\(loadingErrorMessage)\n外部API・リアルタイム株価取得は未実装です。")
                    )
                }
            } else {
                Section("日経225モック銘柄候補") {
                    ContentUnavailableView(
                        "銘柄候補を読み込み中です",
                        systemImage: "hourglass",
                        description: Text("固定モックデータを確認しています。")
                    )
                }
            }

            Section("データ取得") {
                Label("外部API・リアルタイム株価取得は未実装です", systemImage: "wifi.slash")
                Label("ウォッチリストへの追加・保存は今後のステップで実装します", systemImage: "list.bullet.rectangle")
            }
        }
        .navigationTitle("銘柄を追加")
        .onAppear(perform: loadStockCandidates)
    }

    private func loadStockCandidates() {
        do {
            seedFile = try stockMasterProvider.loadSeedFile()
            loadingErrorMessage = nil
        } catch {
            seedFile = nil
            loadingErrorMessage = error.localizedDescription
        }
    }
}

private struct StockMasterSeedRow: View {
    let stock: StockMasterSeed

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stock.name)
                .font(.headline)

            HStack(spacing: 10) {
                Label(stock.code, systemImage: "number")
                Text(stock.market)
                Text(stock.industry)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        StockSearchView()
    }
}
