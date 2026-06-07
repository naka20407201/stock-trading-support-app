//
//  AlertRuleEditorView.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct AlertRuleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let navigationTitle: String
    private let onSave: (String, AlertMetric, ComparisonOperator, String, Bool) throws -> Void

    @State private var name: String
    @State private var metric: AlertMetric
    @State private var comparisonOperator: ComparisonOperator
    @State private var thresholdValueText: String
    @State private var isEnabled: Bool
    @State private var errorMessage: String?

    init(
        rule: AlertRule? = nil,
        onSave: @escaping (String, AlertMetric, ComparisonOperator, String, Bool) throws -> Void
    ) {
        self.navigationTitle = rule == nil ? "条件を追加" : "条件を編集"
        self.onSave = onSave
        _name = State(initialValue: rule?.name ?? "")
        _metric = State(initialValue: rule?.metric ?? .currentPrice)
        _comparisonOperator = State(initialValue: rule?.comparisonOperator ?? .greaterThanOrEqual)
        _thresholdValueText = State(initialValue: rule.map { Self.formatThresholdValue($0.thresholdValue) } ?? "")
        _isEnabled = State(initialValue: rule?.isEnabled ?? true)
    }

    var body: some View {
        Form {
            Section("確認条件") {
                TextField("条件名", text: $name)

                Picker("対象指標", selection: $metric) {
                    ForEach(AlertMetric.selectableCases) { metric in
                        Text(metric.displayName)
                            .tag(metric)
                    }
                }

                Picker("比較演算子", selection: $comparisonOperator) {
                    ForEach(ComparisonOperator.allCases) { comparisonOperator in
                        Text(comparisonOperator.displayName)
                            .tag(comparisonOperator)
                    }
                }

                TextField("しきい値", text: $thresholdValueText)
                    .keyboardType(.decimalPad)

                Toggle("有効", isOn: $isEnabled)
            }

            if let errorMessage {
                Section("入力内容") {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            Section("補足") {
                Label("このStepでは条件の登録・編集のみ行います", systemImage: "info.circle")
                Label("外部API・リアルタイム判定は未実装です", systemImage: "wifi.slash")
            }
        }
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
            }
        }
    }

    private func save() {
        do {
            try onSave(name, metric, comparisonOperator, thresholdValueText, isEnabled)
            dismiss()
        } catch let error as AlertRuleValidationError {
            errorMessage = error.message
        } catch {
            errorMessage = "条件の保存を完了できませんでした。"
        }
    }

    private static func formatThresholdValue(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(value)
    }
}

#Preview {
    NavigationStack {
        AlertRuleEditorView { _, _, _, _, _ in }
    }
}
