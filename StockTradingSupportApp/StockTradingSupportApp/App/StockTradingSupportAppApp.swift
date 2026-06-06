//
//  StockTradingSupportAppApp.swift
//  StockTradingSupportApp
//
//  Created by 中塚康喜 on 2026/06/07.
//

import SwiftData
import SwiftUI

@main
struct StockTradingSupportAppApp: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PersistenceSchemaPlaceholder.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
