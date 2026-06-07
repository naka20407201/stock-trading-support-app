//
//  CustomStockInput.swift
//  StockTradingSupportApp
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct CustomStockInput: Equatable {
    let code: String
    let name: String
    let market: String
    let industry: String

    var normalizedCode: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedMarket: String {
        market.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedIndustry: String {
        industry.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum CustomStockInputValidationError: Error, Equatable, Identifiable {
    case invalidCode
    case emptyName
    case emptyMarket
    case emptyIndustry
    case duplicateCode

    var id: String {
        message
    }

    var message: String {
        switch self {
        case .invalidCode:
            return "銘柄コードは4桁の数字で入力してください。"
        case .emptyName:
            return "銘柄名を入力してください。"
        case .emptyMarket:
            return "市場区分を入力してください。"
        case .emptyIndustry:
            return "業種を入力してください。"
        case .duplicateCode:
            return "同じ銘柄コードはすでにウォッチリストに登録されています。"
        }
    }
}

struct CustomStockInputValidator {
    func validate(
        _ input: CustomStockInput,
        containsCode: (String) -> Bool
    ) -> [CustomStockInputValidationError] {
        var errors: [CustomStockInputValidationError] = []

        if !isHalfWidthFourDigitCode(input.normalizedCode) {
            errors.append(.invalidCode)
        } else if containsCode(input.normalizedCode) {
            errors.append(.duplicateCode)
        }

        if input.normalizedName.isEmpty {
            errors.append(.emptyName)
        }

        if input.normalizedMarket.isEmpty {
            errors.append(.emptyMarket)
        }

        if input.normalizedIndustry.isEmpty {
            errors.append(.emptyIndustry)
        }

        return errors
    }

    private func isHalfWidthFourDigitCode(_ code: String) -> Bool {
        code.range(
            of: #"^[0-9]{4}$"#,
            options: .regularExpression
        ) != nil
    }
}
