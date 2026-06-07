//
//  InvestmentMemoEditorView.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct InvestmentMemoEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let navigationTitle: String
    private let onSave: (String, String) throws -> Void

    @State private var title: String
    @State private var bodyText: String
    @State private var errorMessage: String?

    init(
        memo: InvestmentMemo? = nil,
        onSave: @escaping (String, String) throws -> Void
    ) {
        self.navigationTitle = memo == nil ? "メモを追加" : "メモを編集"
        self.onSave = onSave
        _title = State(initialValue: memo?.title ?? "")
        _bodyText = State(initialValue: memo?.body ?? "")
    }

    var body: some View {
        Form {
            Section("確認メモ") {
                TextField("タイトル", text: $title)

                TextEditor(text: $bodyText)
                    .frame(minHeight: 160)
                    .accessibilityLabel("本文")
            }

            if let errorMessage {
                Section("入力内容") {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
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
            try onSave(title, bodyText)
            dismiss()
        } catch let error as InvestmentMemoValidationError {
            errorMessage = error.message
        } catch {
            errorMessage = "メモの保存を完了できませんでした。"
        }
    }
}

#Preview {
    NavigationStack {
        InvestmentMemoEditorView { _, _ in }
    }
}
