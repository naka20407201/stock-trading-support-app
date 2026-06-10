//
//  ManualStockSnapshotInputEditorView.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct ManualStockSnapshotInputEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let input: ManualStockSnapshotInput?
    private let onSave: (String, String, String, String) throws -> Void

    @State private var currentPriceText: String
    @State private var perText: String
    @State private var pbrText: String
    @State private var volumeText: String
    @State private var errorMessage: String?

    init(
        input: ManualStockSnapshotInput?,
        onSave: @escaping (String, String, String, String) throws -> Void
    ) {
        self.input = input
        self.onSave = onSave
        _currentPriceText = State(initialValue: Self.formatInputValue(input?.currentPrice))
        _perText = State(initialValue: Self.formatInputValue(input?.per))
        _pbrText = State(initialValue: Self.formatInputValue(input?.pbr))
        _volumeText = State(initialValue: Self.formatInputValue(input?.volume))
    }

    var body: some View {
        Form {
            Section("評価用データ") {
                TextField("現在値", text: $currentPriceText)
                    .keyboardType(.decimalPad)
                TextField("PER", text: $perText)
                    .keyboardType(.decimalPad)
                TextField("PBR", text: $pbrText)
                    .keyboardType(.decimalPad)
                TextField("出来高", text: $volumeText)
                    .keyboardType(.decimalPad)
            }

            if let errorMessage {
                Section("入力内容") {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            Section("補足") {
                Label("各項目は任意入力です", systemImage: "text.badge.checkmark")
                Label("少なくとも1つの項目を入力してください", systemImage: "checkmark.circle")
                Label("未入力の指標は評価できません", systemImage: "info.circle")
                Label("手入力値はユーザー確認用の評価データです", systemImage: "pencil")
                Label("削除する場合は詳細画面の削除ボタンを使ってください", systemImage: "trash")
                Label("外部API・リアルタイム株価取得は未実装です", systemImage: "wifi.slash")
            }
        }
        .navigationTitle("評価用データ")
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
            try onSave(currentPriceText, perText, pbrText, volumeText)
            dismiss()
        } catch let error as ManualStockSnapshotInputValidationError {
            errorMessage = error.message
        } catch {
            errorMessage = "評価用データの保存を完了できませんでした。"
        }
    }

    private static func formatInputValue(_ value: Double?) -> String {
        guard let value else {
            return ""
        }

        if value.rounded() == value {
            return String(Int(value))
        }

        return String(value)
    }
}

#Preview {
    NavigationStack {
        ManualStockSnapshotInputEditorView(input: nil) { _, _, _, _ in }
    }
}
