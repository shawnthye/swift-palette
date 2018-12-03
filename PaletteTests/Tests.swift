//
//  Tests.swift
//  PaletteTests
//  This is just a default template for tests
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

import XCTest
//@testable import Palette

class Tests: XCTestCase {
    
    private let array = [String](repeating: "nil", count: 100_000_000)

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    //func testExample() {
    //    // This is an example of a functional test case.
    //    // Use XCTAssert and related functions to verify your tests produce the correct results.
    //}

    //func testPerformanceExample() {
    //    // This is an example of a performance test case.
    //    self.measure {
    //        // Put the code you want to measure the time of here.
    //    }
    //}
    
    //1.093 seconds
    //func testForwardLoop() {
    //    let count = array.count
    //    self.measure {
    //        for i in 0..<count {
    //            _ = array[i]
    //        }
    //    }
    //}
    
//    //8.477 seconds
//    func testReverseLoop() {
//        let count = array.count
//        self.measure {
//            for i in (0..<count).reversed() {
//                _ = array[i]
//            }
//        }
//    }
//
//    //11.950 seconds
//    func testIteratorLoop() {
//        self.measure {
//            for string in array {
//                _ = string
//            }
//        }
//    }
    
    //0.439 seconds
//    func testReverseWhileLoop() {
//        var i = array.count
//        self.measure {
//            while i >= 1 {
//                i += -1
//                _ = array[i]
//
//            }
//
//
//        }
//        print("Reverse while loop - i=\(i)")
//    }
    
    //0.420 seconds
//    func testForwardWhileLoop() {
//        var i = -1
//        let count = array.count - 2
//        self.measure {
//            while i <= count {
//                i += 1
//                _ = array[i]
//            }
//        }
//        print("Forward while loop - i=\(i)")
//    }
}
