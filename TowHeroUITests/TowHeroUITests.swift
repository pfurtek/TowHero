//
//  TowHeroUITests.swift
//  TowHeroUITests
//
//  Created by Binh Ly on 6/20/16.
//  Copyright © 2016 3good LLC. All rights reserved.
//

import XCTest

class TowHeroUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        
        let app = XCUIApplication()
        app.buttons["Go"].tap()
        app.textFields["Destination"].tap()
        
        let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Other).element
        element.tap()
        
        let textField = element.childrenMatchingType(.TextField).element
        textField.tap()
        textField.typeText("Czolgistow Wroclaw")
        app.tables.staticTexts["Wrocław, Poland"].tap()
        app.navigationBars["Destination"].buttons["Done"].tap()
        
    }
    
}
