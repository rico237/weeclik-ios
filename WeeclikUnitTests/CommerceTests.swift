//
//  CommerceTests.swift
//  WeeclikUnitTests
//
//  Created by Herrick Wolber on 26/10/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import XCTest

class CommerceTests: XCTestCase {
    var commerce: Commerce!
    var commerceFromParse: Commerce!
    var commerceFromCommerce: Commerce!
    var decodedCommerce: Commerce!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        commerce = Commerce()
        commerceFromParse = Commerce()
        commerceFromCommerce = Commerce()
        decodedCommerce = Commerce()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        commerce = nil
        commerceFromParse = nil
        commerceFromCommerce = nil
        decodedCommerce = nil
    }

    func commerceFromParseNotNil() {
//        XCTAssertNil(commerceFromParse)
    }
}
