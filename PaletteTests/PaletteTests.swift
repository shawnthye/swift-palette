//
//  PaletteTests.swift
//  PaletteTests
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

import XCTest
@testable import Palette

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

    func testNotNil() {
        //        guard let swatches = palette?.swatches else {
        //            XCTFail("failed to generate palette")
        //            return
        //        }
        //
        //        XCTAssert(swatches.count > 0, "no swatch avaible")
    }
    
    func testBitmap() {
        guard let logo = logo?.cgImage else {
            
            return
        }
        
        let palette = Palette.Builder(bitmap: logo)
//            .resizeBitmapArea(area: 1265)
            .clearFilters()
            .generate()
        let swatches = palette.swatches
        print("Total Color: \(swatches.count)")
        for swatch in swatches {
            print("Color: \(ColorInt.toHexString(swatch.rgb)), population: \(swatch.population)")
        }
    }

}
