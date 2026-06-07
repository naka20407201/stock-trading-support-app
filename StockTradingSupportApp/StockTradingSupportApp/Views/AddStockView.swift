//
//  AddStockView.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import SwiftUI

struct AddStockView: View {
    @ObservedObject var viewModel: WatchlistViewModel

    private let stockMasterProvider: any StockMasterProviding
    private let validator = CustomStockInputValidator()

    @State private var seedFile: StockMasterSeedFile?
    @State private var loadingErrorMessage: String?
    @State private var feedbackMessage: String?
    @State private var validationErrors: [CustomStockInputValidationError] = []

    @State private var customCode = ""
    @State private var customName = ""
    @State private var customMarket = ""
    @State private var customIndustry = ""

    init(
        viewModel: WatchlistViewModel,
        stockMasterProvider: any StockMasterProviding = LocalStockMasterProvider()
    ) {
        self.viewModel = viewModel
        self.stockMasterProvider = stockMasterProvider
    }

    var body: some View {
        List {
            Section("日経225候補から追加") {
                stockCandidateContent
            }

            Section("任意銘柄を追加") {
                TextField("銘柄コード", text: $customCode)
                    .keyboardType(.numberPad)
                TextField("銘柄名", text: $customName)
                TextField("市場区分", text: $customMarket)
                TextField("業種", text: $customIndustry)

                Button {
                    addCustomStock()
                } label: {
                    Label("ウォッチリストに追加", systemImage: "plus.circle")
                }

                if !validationErrors.isEmpty {
                    ForEach(validationErrors) { error in
                        Label(error.message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
            }

            if let feedbackMessage {
                Section("追加結果") {
                    Label(feedbackMessage, systemImage: "info.circle")
                }
            }

            Section("データ取得") {
                Label("外部API・リアルタイム株価取得は未実装です", systemImage: "wifi.slash")
                Label("初期版ではローカルJSONと手入力値を利用します", systemImage: "doc.text")
            }
        }
        .navigationTitle("銘柄を追加")
        .onAppear(perform: loadStockCandidates)
    }

    @ViewBuilder
    private var stockCandidateContent: some View {
        if let seedFile {
            if seedFile.stocks.isEmpty {
                ContentUnavailableView(
                    "日経225候補が未登録です",
                    systemImage: "tray",
                    description: Text("ローカルJSONの銘柄候補を確認してください。")
                )
            } else {
                ForEach(seedFile.stocks) { stock in
                    StockCandidateAddRow(
                        stock: stock,
                        isRegistered: viewModel.contains(code: stock.code)
                    ) {
                        addSeedStock(stock)
                    }
                }
            }
        } else if let loadingErrorMessage {
            ContentUnavailableView(
                "銘柄候補を読み込めませんでした",
                systemImage: "exclamationmark.triangle",
                description: Text(loadingErrorMessage)
            )
        } else {
            ContentUnavailableView(
                "銘柄候補を読み込み中です",
                systemImage: "hourglass",
                description: Text("ローカルJSONを確認しています。")
            )
        }
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

    private func addSeedStock(_ seed: StockMasterSeed) {
        validationErrors = []

        do {
            try viewModel.add(WatchlistItem(seed: seed))
            feedbackMessage = "\(seed.name)をウォッチリストに追加しました。"
        } catch WatchlistRepositoryError.duplicateCode(_) {
            feedbackMessage = CustomStockInputValidationError.duplicateCode.message
        } catch {
            feedbackMessage = "ウォッチリストへの追加を完了できませんでした。"
        }
    }

    private func addCustomStock() {
        let input = CustomStockInput(
            code: customCode,
            name: customName,
            market: customMarket,
            industry: customIndustry
        )

        validationErrors = validator.validate(input, containsCode: viewModel.contains)
        guard validationErrors.isEmpty else {
            feedbackMessage = nil
            return
        }

        let item = WatchlistItem(
            code: input.normalizedCode,
            name: input.normalizedName,
            market: input.normalizedMarket,
            industry: input.normalizedIndustry,
            isNikkei225: false
        )

        do {
            try viewModel.add(item)
            clearCustomInput()
            feedbackMessage = "\(item.name)をウォッチリストに追加しました。"
        } catch WatchlistRepositoryError.duplicateCode(_) {
            validationErrors = [.duplicateCode]
            feedbackMessage = nil
        } catch {
            feedbackMessage = "ウォッチリストへの追加を完了できませんでした。"
        }
    }

    private func clearCustomInput() {
        customCode = ""
        customName = ""
        customMarket = ""
        customIndustry = ""
    }
}

private struct StockCandidateAddRow: View {
    let stock: StockMasterSeed
    let isRegistered: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
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

            Spacer()

            if isRegistered {
                Label("登録済み", systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Button("追加", action: onAdd)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AddStockView(viewModel: WatchlistViewModel())
    }
}
