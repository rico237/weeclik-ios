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
    
    func testSnapshot() {
        snapshot("01Welcome", timeWaitingForIdle: 1)
        
        app/*@START_MENU_TOKEN@*/.collectionViews.containing(.other, identifier:"Barre de défilement verticale, 2 pages")/*[[".collectionViews.containing(.other, identifier:\"Barre de défilement horizontale, 1 page\")",".collectionViews.containing(.other, identifier:\"Barre de défilement verticale, 2 pages\")"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .cell).element(boundBy: 3).children(matching: .other).element.tap()
        
        snapshot("02Detail", timeWaitingForIdle: 0)
        
        app.buttons["Gallery icon"].tap()
        
        snapshot("06Photos")
        
        app/*@START_MENU_TOKEN@*/.buttons["Vidéos"]/*[[".scrollViews.buttons[\"Vidéos\"]",".buttons[\"Vidéos\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.navigationBars["Gallerie"].buttons["Weeclik"].tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 1).tap()
        
        app.navigationBars["Weeclik"].buttons["Retour"].tap()
        app.buttons["Filter icon"].tap()
        
        snapshot("05NombrePartage")
        
        app.buttons["Trier par nombre de partage"].tap()
        app.buttons["OK"].tap()
        app.buttons["Login icon"].tap()
        
        snapshot("03Login")
        
        app.tables/*@START_MENU_TOKEN@*/.cells.containing(.staticText, identifier:"Rose d'or")/*[[".cells.containing(.staticText, identifier:\"199\")",".cells.containing(.staticText, identifier:\"Rose d'or\")"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.staticTexts["En ligne"].tap()
        app.navigationBars["MODIFIER COMMERCE"].buttons["Retour"].tap()
        
        app.buttons["Rechercher"].tap()
        
        snapshot("04Recherche")
        
        app.navigationBars["Recherche"].buttons["Arrêt"].tap()
        
    }

}
