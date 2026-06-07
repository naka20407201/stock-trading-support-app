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
    @State private var editorPresentation: MemoEditorPresentation?

    init(
        watchlistItem: WatchlistItem? = nil,
        memoRepository: any InvestmentMemoRepository = InMemoryInvestmentMemoRepository()
    ) {
        self.watchlistItem = watchlistItem
        _memoViewModel = StateObject(
            wrappedValue: InvestmentMemoViewModel(
                stockCode: watchlistItem?.code ?? "",
                repository: memoRepository
            )
        )
    }

    var body: some View {
        List {
            if let watchlistItem {
                stockInformationSection(watchlistItem)
                memoSection
            } else {
                Section("銘柄詳細") {
                    Text("現在は初期画面です")
                    Text("ウォッチリストから遷移した場合、銘柄情報と確認メモを表示します。")
                        .foregroundStyle(.secondary)
                }
            }

            Section("ユーザー設定条件") {
                Label("条件設定は今後実装します", systemImage: "slider.horizontal.3")
                Label("条件履歴は今後実装します", systemImage: "clock.arrow.circlepath")
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
        .onAppear(perform: memoViewModel.refresh)
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
    private var memoSection: some View {
        Section("確認メモ") {
            if memoViewModel.memos.isEmpty {
                ContentUnavailableView(
                    "確認メモは未登録です",
                    systemImage: "note.text",
                    description: Text("気になった点を記録できます。")
                )
            } else {
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
        for index in offsets {
            let memo = memoViewModel.memos[index]
            memoViewModel.deleteMemo(id: memo.id)
        }
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
            memoRepository: InMemoryInvestmentMemoRepository()
        )
    }
}
