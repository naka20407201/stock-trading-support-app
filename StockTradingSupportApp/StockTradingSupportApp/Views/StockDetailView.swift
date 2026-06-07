//
//  StockDetailView.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftUI

struct StockDetailView: View {
    let watchlistItem: WatchlistItem?

    @StateObject private var memoViewModel: InvestmentMemoViewModel
    @StateObject private var manualInputViewModel: ManualStockSnapshotInputViewModel
    private let alertRuleRepository: any AlertRuleRepository
    private let stockDataProvider: any StockDataProviding
    private let alertMatchHistoryRepository: any AlertMatchHistoryRepository
    @State private var editorPresentation: MemoEditorPresentation?
    @State private var isManualInputEditorPresented = false

    init(
        watchlistItem: WatchlistItem? = nil,
        memoRepository: any InvestmentMemoRepository = InMemoryInvestmentMemoRepository(),
        alertRuleRepository: any AlertRuleRepository = InMemoryAlertRuleRepository(),
        stockDataProvider: any StockDataProviding = MockStockDataProvider(),
        alertMatchHistoryRepository: any AlertMatchHistoryRepository = InMemoryAlertMatchHistoryRepository(),
        manualStockSnapshotInputRepository: any ManualStockSnapshotInputRepository = InMemoryManualStockSnapshotInputRepository()
    ) {
        self.watchlistItem = watchlistItem
        self.alertRuleRepository = alertRuleRepository
        self.stockDataProvider = stockDataProvider
        self.alertMatchHistoryRepository = alertMatchHistoryRepository
        _memoViewModel = StateObject(
            wrappedValue: InvestmentMemoViewModel(
                stockCode: watchlistItem?.code ?? "",
                repository: memoRepository
            )
        )
        _manualInputViewModel = StateObject(
            wrappedValue: ManualStockSnapshotInputViewModel(
                stockCode: watchlistItem?.code ?? "",
                repository: manualStockSnapshotInputRepository
            )
        )
    }

    var body: some View {
        List {
            if let watchlistItem {
                stockInformationSection(watchlistItem)
                manualInputSection
                memoSection
                AlertRuleListView(
                    stockCode: watchlistItem.code,
                    repository: alertRuleRepository
                )
                AlertEvaluationView(
                    stockCode: watchlistItem.code,
                    alertRuleRepository: alertRuleRepository,
                    stockDataProvider: stockDataProvider,
                    historyRepository: alertMatchHistoryRepository
                )
            } else {
                Section("銘柄詳細") {
                    Text("現在は初期画面です")
                    Text("ウォッチリストから遷移した場合、銘柄情報、確認メモ、ユーザー設定条件を表示します。")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(watchlistItem?.name ?? "銘柄詳細")
        .toolbar {
            if watchlistItem != nil {
                Button {
                    editorPresentation = .add
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("メモを追加")
            }
        }
        .sheet(item: $editorPresentation) { presentation in
            NavigationStack {
                InvestmentMemoEditorView(memo: presentation.memo) { title, body in
                    switch presentation {
                    case .add:
                        try memoViewModel.addMemo(title: title, body: body)
                    case .edit(let memo):
                        try memoViewModel.updateMemo(
                            id: memo.id,
                            title: title,
                            body: body
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $isManualInputEditorPresented) {
            NavigationStack {
                ManualStockSnapshotInputEditorView(input: manualInputViewModel.input) { currentPriceText, perText, pbrText, volumeText in
                    try manualInputViewModel.saveInput(
                        currentPriceText: currentPriceText,
                        perText: perText,
                        pbrText: pbrText,
                        volumeText: volumeText
                    )
                }
            }
        }
        .onAppear {
            memoViewModel.refresh()
            manualInputViewModel.refresh()
        }
    }

    private func stockInformationSection(_ item: WatchlistItem) -> some View {
        Section("ユーザーが確認する銘柄情報") {
            LabeledContent("銘柄名", value: item.name)
            LabeledContent("銘柄コード", value: item.code)
            LabeledContent("市場区分", value: item.market)
            LabeledContent("業種", value: item.industry)
            LabeledContent("日経225標準候補", value: item.isNikkei225 ? "はい" : "いいえ")
        }
    }

    @ViewBuilder
    private var manualInputSection: some View {
        Section("評価用データ") {
            if let errorMessage = manualInputViewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            if let input = manualInputViewModel.input {
                LabeledContent("データソース", value: input.sourceName)
                LabeledContent("更新日時", value: input.updatedAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("現在値", value: formattedManualInputValue(input.currentPrice, metric: .currentPrice))
                LabeledContent("PER", value: formattedManualInputValue(input.per, metric: .per))
                LabeledContent("PBR", value: formattedManualInputValue(input.pbr, metric: .pbr))
                LabeledContent("出来高", value: formattedManualInputValue(input.volume, metric: .volume))
            } else if manualInputViewModel.errorMessage == nil {
                ContentUnavailableView(
                    "入力値は未登録です",
                    systemImage: "square.and.pencil",
                    description: Text("未登録の場合は固定モック値を使って評価します。")
                )
            }

            Button {
                isManualInputEditorPresented = true
            } label: {
                Label(manualInputViewModel.input == nil ? "評価用データを入力" : "評価用データを編集", systemImage: "square.and.pencil")
            }

            if manualInputViewModel.input != nil {
                Button(role: .destructive) {
                    manualInputViewModel.deleteInput()
                } label: {
                    Label("入力値を削除", systemImage: "trash")
                }
            }

            Label("未入力の指標は評価できません", systemImage: "info.circle")
                .foregroundStyle(.secondary)
            Label("外部API・リアルタイム株価取得は未実装です", systemImage: "wifi.slash")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var memoSection: some View {
        Section("確認メモ") {
            if let errorMessage = memoViewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            if memoViewModel.memos.isEmpty && memoViewModel.errorMessage == nil {
                ContentUnavailableView(
                    "確認メモは未登録です",
                    systemImage: "note.text",
                    description: Text("気になった点を記録できます。")
                )
            } else if !memoViewModel.memos.isEmpty {
                ForEach(memoViewModel.memos) { memo in
                    Button {
                        editorPresentation = .edit(memo)
                    } label: {
                        InvestmentMemoRow(memo: memo)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteMemos)
            }
        }
    }

    private func deleteMemos(at offsets: IndexSet) {
        let idsToDelete = offsets.map { memoViewModel.memos[$0].id }

        for id in idsToDelete {
            memoViewModel.deleteMemo(id: id)
        }
    }

    private func formattedManualInputValue(_ value: Double?, metric: AlertMetric) -> String {
        guard let value else {
            return "未入力"
        }

        return metric.formattedValue(value)
    }
}

private enum MemoEditorPresentation: Identifiable {
    case add
    case edit(InvestmentMemo)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let memo):
            return memo.id.uuidString
        }
    }

    var memo: InvestmentMemo? {
        switch self {
        case .add:
            return nil
        case .edit(let memo):
            return memo
        }
    }
}

private struct InvestmentMemoRow: View {
    let memo: InvestmentMemo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(memo.title)
                .font(.headline)

            Text(memo.body.isEmpty ? "本文は未入力です" : memo.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Text("更新: \(memo.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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
            ),
            memoRepository: InMemoryInvestmentMemoRepository(),
            alertRuleRepository: InMemoryAlertRuleRepository(),
            stockDataProvider: MockStockDataProvider(),
            alertMatchHistoryRepository: InMemoryAlertMatchHistoryRepository(),
            manualStockSnapshotInputRepository: InMemoryManualStockSnapshotInputRepository()
        )
    }
}
