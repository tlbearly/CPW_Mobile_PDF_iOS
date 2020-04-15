//
//  MapViewerTests.swift
//  MapViewerTests
//
//  Created by Brittney Bearly on 4/10/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

import XCTest
@testable import MapViewer

class MapViewerTests: XCTestCase {

    // MARK: PDFMap Class Tests
    
    // Confirm that the PDFMap initializer return a Map object when passed valid parameters.
    func testPDFMapInitSucceeds(){
        let map = PDFMap.init(name: "Wellington.pdf", thumbnail: nil)
        XCTAssertNotNil(map)
        //(name: "Wellington.pdf", thumbnail: nil, bounds: [1.0,1.0,1.0,1.0])
    }

    func testPDFMapInitFaled(){
        // Empty String
        let emptyName = PDFMap.init(name: "", thumbnail: nil)
        XCTAssertNil(emptyName)
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
