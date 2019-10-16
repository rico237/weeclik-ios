//
//  WeeClikUITests.swift
//  WeeClikUITests
//
//  Created by Herrick Wolber on 23/04/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import XCTest

class WeeClikUITests: XCTestCase {

    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        app.launchArguments = ["ResetDefaults", "NoAnimations", "UserHasRegistered"]
        setupSnapshot(app)
        app.launch()
        
        
        
        
        
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
//        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
//        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        
        let app = XCUIApplication()
        snapshot("01Welcome", timeWaitingForIdle: 2)
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .collectionView).element(boundBy: 1).children(matching: .cell).element(boundBy: 1).children(matching: .other).element
        element.tap()
        
        let okButton = app.alerts["Aucun compte Mail"].buttons["OK"]
        okButton.tap()
        snapshot("02Detail", timeWaitingForIdle: 2)
        app.buttons["Gallery icon"].tap()
        app.collectionViews.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.tap()
        app.buttons["close white"].tap()
        app.navigationBars["Gallerie"].buttons["Weeclik"]/*@START_MENU_TOKEN@*/.tap()/*[[".tap()",".press(forDuration: 2.0);"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/
        
        let retourButton = app.navigationBars["Weeclik"].buttons["Retour"]
        retourButton.tap()
        app.buttons["Login icon"].tap()
        snapshot("03Login")
        app.navigationBars["Mon Profil"].buttons["Arrêt"].tap()
        app.buttons["Filter icon"].tap()
        app.buttons["Trier par position"].tap()
        app.buttons["OK"].tap()
        addUIInterruptionMonitor(withDescription: "System Dialog") {
            (alert) -> Bool in
            let button = alert.buttons.element(boundBy: 1)
            if button.exists {
                button.tap()
            }
            return true
        }
        addUIInterruptionMonitor(withDescription: "Allow “Weeclik” to access your location while you are using the app?") {
            (alert) -> Bool in
            let button = alert.buttons.element(boundBy: 1)
            if button.exists {
                button.tap()
            }
            return true
        }
        element.tap()
        okButton.tap()
        retourButton.tap()
        
        app.buttons["SearchIcon"].tap()
        snapshot("04Recherche")
        app.navigationBars["Recherche"].buttons["Arrêt"].tap()
        
        let filterIconButton = app.buttons["Filter icon"]
        filterIconButton.tap()
        app.buttons["Trier par position"].tap()
        
        let okButtonA = app.buttons["OK"]
        okButtonA.tap()
        filterIconButton.tap()
        app.buttons["Trier par nombre de partage"].tap()
        okButtonA.tap()
        snapshot("05NombrePartage")
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
