//
//  SwatchTests.swift
//  PaletteTests
//
//  Created by Shawn Thye on 05/12/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

import XCTest
@testable import Palette

class SwatchTests: XCTestCase {
    
    func testWhite() {
        let swatch = Palette.Swatch(red: 255, green: 255, blue: 255, population: 1)
        
        XCTAssertEqual(swatch.red, 255)
        XCTAssertEqual(swatch.green, 255)
        XCTAssertEqual(swatch.blue, 255)
        XCTAssertEqual(swatch.rgb, 0xFFFFFFFF)
        XCTAssertEqual(swatch.hexadecimalOfRGB, "FFFFFF")
        XCTAssertEqual(swatch.hexadecimalOfRGB, ColorInt.toHexadecimalOfRGB(swatch.rgb))
        
        XCTAssertEqual(ColorInt.toHexString(swatch.rgb), "FFFFFFFF")
        XCTAssertEqual(ColorInt.toHexadecimalOfRGB(swatch.rgb), "FFFFFF")
    }
}
