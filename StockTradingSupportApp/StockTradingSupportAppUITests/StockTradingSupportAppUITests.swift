//
//  StockTradingSupportAppUITests.swift
//  StockTradingSupportAppUITests
//
//  Created by 中塚康喜 on 2026/06/07.
//

import XCTest

final class StockTradingSupportAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testAddStockShowsNikkei225Candidates() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["銘柄を追加"].tap()

        XCTAssertTrue(app.staticTexts["日経225候補から追加"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["トヨタ自動車"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["7203"].exists)
        XCTAssertTrue(app.staticTexts["登録済み"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
