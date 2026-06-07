//
//  AlertEvaluationView.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct AlertEvaluationView: View {
    @StateObject private var viewModel: AlertEvaluationViewModel

    init(
        stockCode: String,
        alertRuleRepository: any AlertRuleRepository,
        stockDataProvider: any StockDataProviding,
        historyRepository: any AlertMatchHistoryRepository
    ) {
        _viewModel = StateObject(
            wrappedValue: AlertEvaluationViewModel(
                stockCode: stockCode,
                alertRuleRepository: alertRuleRepository,
                stockDataProvider: stockDataProvider,
                historyRepository: historyRepository
            )
        )
    }

    var body: some View {
        evaluationSection
        historySection
    }

    private var evaluationSection: some View {
        Section("条件評価") {
            Button {
                viewModel.evaluate()
            } label: {
                Label("条件を評価", systemImage: "checklist")
            }

            Label("外部API・リアルタイム株価取得は未実装です", systemImage: "wifi.slash")
                .foregroundStyle(.secondary)

            if let snapshot = viewModel.snapshot {
                LabeledContent("データソース", value: snapshot.sourceName)
                LabeledContent("取得時刻", value: snapshot.capturedAt.formatted(date: .abbreviated, time: .shortened))
            } else {
                ContentUnavailableView(
                    "評価用データがありません",
                    systemImage: "tray",
                    description: Text("固定モック株価が未登録の銘柄です。")
                )
            }

            if viewModel.evaluations.isEmpty {
                Text("条件を評価すると結果を表示します。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.evaluations) { item in
                    AlertEvaluationRow(item: item)
                }
            }
        }
    }

    private var historySection: some View {
        Section("条件一致履歴") {
            if viewModel.histories.isEmpty {
                ContentUnavailableView(
                    "条件一致履歴は未登録です",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("条件に一致した場合、ここに履歴を表示します。")
                )
            } else {
                Button(role: .destructive) {
                    viewModel.clearHistories()
                } label: {
                    Label("履歴をすべて削除", systemImage: "trash")
                }

                ForEach(viewModel.histories) { history in
                    AlertMatchHistoryRow(history: history)
                }
            }
        }
        .onAppear(perform: viewModel.refresh)
    }
}

private struct AlertEvaluationRow: View {
    let item: AlertRuleEvaluationDisplayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.rule.name)
                    .font(.headline)

                Spacer()

                Text(item.result.displayName)
                    .font(.caption)
                    .foregroundStyle(resultColor)
            }

            Text(item.conditionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LabeledContent("観測値", value: item.observedValueText)

            Text(item.result.detailText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var resultColor: Color {
        switch item.result {
        case .matched:
            return .green
        case .notMatched:
            return .secondary
        case .unavailable:
            return .orange
        case .disabled:
            return .secondary
        }
    }
}

private struct AlertMatchHistoryRow: View {
    let history: AlertMatchHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(history.alertRuleName)
                .font(.headline)

            Text(conditionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LabeledContent("観測値", value: history.metric.formattedValue(history.observedValue))
            LabeledContent("一致日時", value: history.matchedAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("データソース", value: history.sourceName)
        }
        .padding(.vertical, 4)
    }

    private var conditionText: String {
        "\(history.metric.displayName) \(history.comparisonOperator.displayName) \(history.metric.formattedValue(history.thresholdValue))"
    }
}

#Preview {
    List {
        AlertEvaluationView(
            stockCode: "7203",
            alertRuleRepository: InMemoryAlertRuleRepository(),
            stockDataProvider: MockStockDataProvider(),
            historyRepository: InMemoryAlertMatchHistoryRepository()
        )
    }
}
