//
//  RepositoryReadStatusProviding.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

protocol RepositoryReadStatusProviding: AnyObject {
    var readErrorMessage: String? { get }
}

enum RepositoryStatusMessage {
    static let readFailed = "データを読み込めませんでした。再度開き直して確認してください。"
    static let deleteFailed = "データを削除できませんでした。再度開き直して確認してください。"
}
