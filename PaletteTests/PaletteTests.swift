//
//  PaletteTests.swift
//  PaletteTests
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

import XCTest
import Palette

class PaletteTests: XCTestCase {
    
    var logo: UIImage?
    
    override func setUp() {
        logo = UIImage(named: "instagram_logo.jpg",
                       in: Bundle(for: PaletteTests.self),
                       compatibleWith: nil)
        assert(logo != nil, "logo not found")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGenerate() {
        guard let logo = logo?.cgImage else {
            return
        }
        
        let palette = Palette.from(bitmap: logo)
            .generate()
        
        let swatches = palette.swatches
        XCTAssertEqual(swatches.count, 16)
    }
    
    func testGenerateAsync() {
        guard let logo = logo?.cgImage else {
            return
        }
        var results: [Palette.Swatch]?
        let expectation = self.expectation(description: "")
        Palette.Builder(bitmap: logo)
            .clearFilters()
            .generate { palette in
                results = palette.swatches
                expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
        
        XCTAssertNotNil(results)
        
        guard let swatches = results else {
            assertionFailure()
            return
        }
        
        XCTAssertEqual(swatches.count, 16)
        
        print("Total Color: \(swatches.count)")
        for swatch in swatches {
            print("Color: \(ColorInt.toHexString(swatch.rgb)), population: \(swatch.population)")
        }
    }
    
}
