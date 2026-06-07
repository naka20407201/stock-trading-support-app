//
//  InvestmentMemo.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct InvestmentMemo: Identifiable, Equatable, Hashable {
    let id: UUID
    let stockCode: String
    let title: String
    let body: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        stockCode: String,
        title: String,
        body: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.stockCode = stockCode
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func updating(title: String, body: String, updatedAt: Date = Date()) -> InvestmentMemo {
        InvestmentMemo(
            id: id,
            stockCode: stockCode,
            title: title,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

enum InvestmentMemoValidationError: Error, Equatable, Identifiable {
    case emptyTitle

    var id: String {
        message
    }

    var message: String {
        switch self {
        case .emptyTitle:
            return "タイトルを入力してください。"
        }
    }
}
