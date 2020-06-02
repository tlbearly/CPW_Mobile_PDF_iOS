//
//  MapViewerTests.swift
//  MapViewerTests
//
//  Created by Tammy Bearly on 4/10/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

import XCTest
@testable import MapVieweriOS

class MapViewerTests: XCTestCase {

    // MARK: PDFMap Class Tests
    
    // Confirm that the PDFMap initializer returns a Map object when passed valid parameters.
    func testPDFMapInitSucceeds(){
        let map = PDFMap.init(fileName: "Wellington.pdf")
        XCTAssertNotNil(map)
    }

    func testPDFMapInitFailed(){
        // Empty String
        let emptyName = PDFMap.init(fileName: "")
        XCTAssertNil(emptyName)
    }
    
    func testPDFMapInitFailed2() {
        let notExistFile = PDFMap.init(fileName: "notExists.pdf")
        XCTAssertNil(notExistFile)
    }
    
    
    
    
/*    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }*/

}
