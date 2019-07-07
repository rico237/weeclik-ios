//
//  WeeClikUnitTests.swift
//  WeeClikUnitTests
//
//  Created by Herrick Wolber on 06/07/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import XCTest


class WeeClikUnitTests: XCTestCase {
    
    var commerceInit: Commerce!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        commerceInit = Commerce()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        commerceInit = nil
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssert(commerceInit.adresse != nil, "Adresse must not be nil")
    }

}
