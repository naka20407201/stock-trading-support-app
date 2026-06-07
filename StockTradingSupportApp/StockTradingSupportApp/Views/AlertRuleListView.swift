//
//  AlertRuleListView.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct AlertRuleListView: View {
    @StateObject private var viewModel: AlertRuleViewModel
    @State private var editorPresentation: AlertRuleEditorPresentation?
    @State private var errorMessage: String?

    init(
        stockCode: String,
        repository: any AlertRuleRepository
    ) {
        _viewModel = StateObject(
            wrappedValue: AlertRuleViewModel(
                stockCode: stockCode,
                repository: repository
            )
        )
    }

    var body: some View {
        Section("ユーザー設定条件") {
            Button {
                editorPresentation = .add
            } label: {
                Label("条件を追加", systemImage: "plus.circle")
            }

            if viewModel.rules.isEmpty {
                ContentUnavailableView(
                    "ユーザー設定条件は未登録です",
                    systemImage: "slider.horizontal.3",
                    description: Text("銘柄ごとの確認条件を登録できます。")
                )
            } else {
                ForEach(viewModel.rules) { rule in
                    AlertRuleRow(
                        rule: rule,
                        thresholdText: viewModel.formattedThresholdValue(for: rule),
                        onEdit: {
                            editorPresentation = .edit(rule)
                        },
                        onToggleEnabled: {
                            toggleEnabled(id: rule.id)
                        }
                    )
                }
                .onDelete(perform: deleteRules)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            Label("通知送信は今後実装します", systemImage: "bell.slash")
                .foregroundStyle(.secondary)
        }
        .sheet(item: $editorPresentation) { presentation in
            NavigationStack {
                AlertRuleEditorView(rule: presentation.rule) { name, metric, comparisonOperator, thresholdValueText, isEnabled in
                    switch presentation {
                    case .add:
                        try viewModel.addRule(
                            name: name,
                            metric: metric,
                            comparisonOperator: comparisonOperator,
                            thresholdValueText: thresholdValueText,
                            isEnabled: isEnabled
                        )
                    case .edit(let rule):
                        try viewModel.updateRule(
                            id: rule.id,
                            name: name,
                            metric: metric,
                            comparisonOperator: comparisonOperator,
                            thresholdValueText: thresholdValueText,
                            isEnabled: isEnabled
                        )
                    }
                }
            }
        }
        .onAppear(perform: viewModel.refresh)
    }

    private func deleteRules(at offsets: IndexSet) {
        let idsToDelete = offsets.map { viewModel.rules[$0].id }

        for id in idsToDelete {
            viewModel.deleteRule(id: id)
        }
    }

    private func toggleEnabled(id: AlertRule.ID) {
        do {
            try viewModel.toggleEnabled(id: id)
            errorMessage = nil
        } catch {
            errorMessage = "条件の有効状態を更新できませんでした。"
        }
    }
}

private enum AlertRuleEditorPresentation: Identifiable {
    case add
    case edit(AlertRule)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let rule):
            return rule.id.uuidString
        }
    }

    var rule: AlertRule? {
        switch self {
        case .add:
            return nil
        case .edit(let rule):
            return rule
        }
    }
}

private struct AlertRuleRow: View {
    let rule: AlertRule
    let thresholdText: String
    let onEdit: () -> Void
    let onToggleEnabled: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(rule.name)
                        .font(.headline)

                    Text(conditionDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("更新: \(rule.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onToggleEnabled) {
                Label(rule.isEnabled ? "有効" : "無効", systemImage: rule.isEnabled ? "checkmark.circle" : "pause.circle")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(rule.isEnabled ? "条件を無効にする" : "条件を有効にする")
        }
        .padding(.vertical, 4)
    }

    private var conditionDescription: String {
        "\(rule.metric.displayName) \(rule.comparisonOperator.displayName) \(thresholdText)"
    }
}

#Preview {
    List {
        AlertRuleListView(
            stockCode: "7203",
            repository: InMemoryAlertRuleRepository()
        )
    }
}
