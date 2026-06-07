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
                        onEdit: {
                            editorPresentation = .edit(rule)
                        },
                        onToggleEnabled: {
                            viewModel.toggleEnabled(id: rule.id)
                        }
                    )
                }
                .onDelete(perform: deleteRules)
            }

            Label("条件の評価・通知・履歴作成は今後実装します", systemImage: "clock.arrow.circlepath")
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
        "\(rule.metric.displayName) \(rule.comparisonOperator.displayName) \(formattedThresholdValue) \(rule.metric.unitName)"
    }

    private var formattedThresholdValue: String {
        if rule.thresholdValue.rounded() == rule.thresholdValue {
            return String(Int(rule.thresholdValue))
        }

        return String(rule.thresholdValue)
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
