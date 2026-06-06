//
//  PersistenceSchemaPlaceholder.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import Foundation
import SwiftData

@Model
final class PersistenceSchemaPlaceholder {
    var createdAt: Date

    init(createdAt: Date = .now) {
        self.createdAt = createdAt
    }
}
