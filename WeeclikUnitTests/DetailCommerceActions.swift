//
//  DetailCommerceActions.swift
//  WeeclikUnitTests
//
//  Created by Herrick Wolber on 26/10/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import XCTest

final class DetailCommerceActions: XCTestCase {
    
    func testSiteWebValidURLs() {
        // Not valid urls
        XCTAssertFalse("http:/weeclik.com".isValidURL(), "Message")
        XCTAssertFalse("htp://w.weeclik.com".isValidURL())
        XCTAssertFalse("https://www.weeclik.com/3dz_dz-éfq".isValidURL())
        XCTAssertFalse("weeclik.".isValidURL())
        XCTAssertFalse("weeclik".isValidURL())
        XCTAssertFalse("w.weeclik.com".isValidURL())
        XCTAssertFalse("w.weeclik.com".isValidURL())
        XCTAssertFalse("www.weeclik.com/3dz_dz-éfq".isValidURL())
        
        // Random text
        XCTAssertFalse("".isValidURL())
        XCTAssertFalse("0712".isValidURL())
        
        // Valid urls
        // FIXME: check regex and set http optionnal
        XCTAssertTrue("www.weeclik.com".isValidURL())
        XCTAssertTrue("weeclik.com".isValidURL())
        XCTAssertTrue("weeclik.com".isValidURL())
        XCTAssertTrue("www.weeclik.com/".isValidURL())
        XCTAssertTrue("www.weeclik.com/3dz_dz-efq".isValidURL())
        XCTAssertTrue("api.weeclik.com/".isValidURL())
        XCTAssertTrue("https://weeclik.com".isValidURL())
        XCTAssertTrue("https://www.weeclik.com".isValidURL())
        XCTAssertTrue("https://www.weeclik.com/".isValidURL())
        XCTAssertTrue("https://www.weeclik.com/3dz_dz-efq".isValidURL())
        XCTAssertTrue("https://api.weeclik.com/".isValidURL())
        XCTAssertTrue("https://w.weeclik.com".isValidURL())
    }
}
