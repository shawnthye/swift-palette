//
//  ColorCutQuantizerTests.swift
//  PaletteTests
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

import XCTest
@testable import Palette

class ColorCutQuantizerTests : XCTestCase {
    
    func testPixels24() {
        let quantizer = ColorCutQuantizer(pixels: ColorCutQuantizerTests.pixels24,
                                          maxColors: Palette.defaultCalculateNumberColors,
                                          filters: nil)
        
        XCTAssertEqual(quantizer.quantizedColors,
                       [Palette.Swatch(color: 0xff306890, population: 1),
                        Palette.Swatch(color: 0xff386090, population: 1),
                        Palette.Swatch(color: 0xff386890, population: 10),
                        Palette.Swatch(color: 0xff407098, population: 8),
                        Palette.Swatch(color: 0xff4878a0, population: 4)],
                       "unexpeceted swatches created")
    }
    
    func testPixels1302() {
        let quantizer = ColorCutQuantizer(pixels: ColorCutQuantizerTests.pixels1302,
                                          maxColors: Palette.defaultCalculateNumberColors,
                                          filters: nil)
        
        XCTAssertEqual(quantizer.quantizedColors,
                       [Palette.Swatch(color: 0xff386898, population: 9),
                        Palette.Swatch(color: 0xff4870a0, population: 5),
                        Palette.Swatch(color: 0xff306890, population: 54),
                        Palette.Swatch(color: 0xffb8c8d8, population: 1),
                        Palette.Swatch(color: 0xff90a8c0, population: 1),
                        Palette.Swatch(color: 0xff5080a0, population: 1),
                        Palette.Swatch(color: 0xff306088, population: 75),
                        Palette.Swatch(color: 0xff5078a0, population: 1),
                        Palette.Swatch(color: 0xffe8e8f0, population: 1),
                        Palette.Swatch(color: 0xff386890, population: 501),
                        Palette.Swatch(color: 0xff4878a0, population: 118),
                        Palette.Swatch(color: 0xffc0d0e0, population: 1),
                        Palette.Swatch(color: 0xff407098, population: 492),
                        Palette.Swatch(color: 0xfff8f8f8, population: 35),
                        Palette.Swatch(color: 0xff487898, population: 6),
                        Palette.Swatch(color: 0xffd8e0e8, population: 1)],
                       "unexpeceted swatches created")
    }
}
