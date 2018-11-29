//
//  ColorCutQuantizer.swift
//  Palette
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

/**
 * An color quantizer based on the Median-cut algorithm, but optimized for picking out distinct
 * colors rather than representation colors.
 *
 * The color space is represented as a 3-dimensional cube with each dimension being an RGB
 * component. The cube is then repeatedly divided until we have reduced the color space to the
 * requested number of colors. An average color is then generated from each cube.
 *
 * What makes this different to median-cut is that median-cut divided cubes so that all of the cubes
 * have roughly the same population, where this quantizer divides boxes based on their color volume.
 * This means that the color space is divided into distinct colors, rather than representative
 * colors.
 */
final class ColorCutQuantizer {
    
    static let COMPONENT_RED = -3
    static let COMPONENT_GREEN = -2
    static let COMPONENT_BLUE = -1
    
    private static let QUANTIZE_WORD_WIDTH = 5
    private static let QUANTIZE_WORD_MASK = (1 << QUANTIZE_WORD_WIDTH) - 1
    
    private var mColors: [Int] = []
    private var mHistogram: [Int] = []
    private(set) var quantizedColors: [Palette.Swatch] = []
    private var mFilters: [Palette.Filter]?
    
    private var mTempHsl: [Float] = [Float](repeating: 0, count: 3)
    
    init(pixels: [Int], maxColors: Int, filters: [Palette.Filter]?) {
        mFilters = filters
        
        var pixels = pixels
        var hist: [Int] = [Int](repeating: 0, count: (1 << (ColorCutQuantizer.QUANTIZE_WORD_WIDTH * 3)))
        
        for (i, pixel) in pixels.enumerated() {
            let quantizedColor = ColorCutQuantizer.quantizeFromRgb888(pixel)
            // Now update the pixel value to the quantized value
            pixels[i] = quantizedColor
            // And update the histogram
            hist[quantizedColor] += 1
        }
        
        // Histogram created
        
        // Now let's count the number of distinct colors
        var distinctColorCount = 0
        for color in 0..<hist.count {
            if hist[color] > 0 && shouldIgnoreColor(color565: color) {
                // If we should ignore the color, set the population to 0
                hist[color] = 0
            }
            if hist[color] > 0 {
                // If the color has population, increase the distinct color count
                distinctColorCount += 1
            }
        } //Filtered colors and distinct colors counted
        
        mHistogram = hist
        // Histogram updated
        
        // Now lets go through create an array consisting of only distinct colors
        var colors = [Int](repeating: 0, count: distinctColorCount)
        var distinctColorIndex = 0
        for (i, color) in mHistogram.enumerated() where color > 0 {
            colors[distinctColorIndex] = i
            distinctColorIndex += 1
        }
        mColors = colors //Distinct colors copied into array
        
        var quantizedColors = [Palette.Swatch]()
        if distinctColorCount <= maxColors {
            // The image has fewer colors than the maximum requested, so just return the colors
            for color in colors {
                quantizedColors.append(Palette.Swatch(color: ColorCutQuantizer.approximateToRgb888(color), population: hist[color]))
            } //Too few colors present. Copied to Swatches
        } else {
            // We need use quantization to reduce the number of colors
            quantizedColors = quantizePixels(maxColors) //Quantized colors computed
        }
        
        self.quantizedColors = quantizedColors
    }
    
    private func quantizePixels(_ maxColors: Int) -> [Palette.Swatch] {
        // Create the priority queue which is sorted by volume descending. This means we always
        // split the largest box in the queue
        var pq = PriorityQueue<Vbox>()
        
        // To start, offer a box which contains all of the colors
        pq.push(Vbox(colorCutQuantizer: self,
                     lowerIndex: 0,
                     upperIndex: mColors.count - 1))
        
        // Now go through the boxes, splitting them until we have reached maxColors or there are no
        // more boxes to split
        splitBoxes(queue: &pq, maxSize: maxColors)
        
        // Finally, return the average colors of the color boxes
        return generateAverageColors(vboxes: pq)
    }
    
    /**
     * Iterate through the {@link java.util.Queue}, popping
     * {@link ColorCutQuantizer.Vbox} objects from the queue
     * and splitting them. Once split, the new box and the remaining box are offered back to the
     * queue.
     *
     * @param queue {@link java.util.PriorityQueue} to poll for boxes
     * @param maxSize Maximum amount of boxes to split
     */
    private func splitBoxes(queue: inout PriorityQueue<Vbox>, maxSize: Int) {
        while (queue.count < maxSize) {
            guard let vbox = queue.pop(), vbox.canSplit() else {
                // All boxes split
                // If we get here then there are no more boxes to split, so return
                return
            }
            
            // First split the box, and offer the result
            queue.push(vbox.splitBox()) //Box split
            
            // Then offer the box back
            queue.push(vbox)
        }
    }
    
    private func generateAverageColors(vboxes: PriorityQueue<Vbox>) -> [Palette.Swatch] {
        var colors = [Palette.Swatch]()
        for vbox in vboxes {
            let swatch = vbox.getAverageColor()
            if (!shouldIgnoreColor(color: swatch)) {
                // As we're averaging a color box, we can still get colors which we do not want, so
                // we check again here
                colors.append(swatch)
            }
        }
        return colors
    }
    
    /**
     * Modify the significant octet in a packed color int. Allows sorting based on the value of a
     * single color component. This relies on all components being the same word size.
     *
     * @see Vbox#findSplitPoint()
     */
    static func modifySignificantOctet(_ a: inout [Int], _ dimension: Int, _ lower: Int, _ upper: Int) {
        switch (dimension) {
        case COMPONENT_RED:
            // Already in RGB, no need to do anything
            break
        case COMPONENT_GREEN:
            // We need to do a RGB to GRB swap, or vice-versa
            for (i, color) in a.enumerated() {
                a[i] = quantizedGreen(color) << (QUANTIZE_WORD_WIDTH + QUANTIZE_WORD_WIDTH)
                    | quantizedRed(color) << QUANTIZE_WORD_WIDTH
                    | quantizedBlue(color)
            }
            break
        case COMPONENT_BLUE:
            // We need to do a RGB to BGR swap, or vice-versa
            for (i, color) in a.enumerated() {
                a[i] = quantizedBlue(color) << (QUANTIZE_WORD_WIDTH + QUANTIZE_WORD_WIDTH)
                    | quantizedGreen(color) << QUANTIZE_WORD_WIDTH
                    | quantizedRed(color)
            }
            break
        default:
            break
        }
    }
    
    private func shouldIgnoreColor(color565: Int) -> Bool {
        let rgb = ColorCutQuantizer.approximateToRgb888(color565)
        ColorUtils.colorToHSL(color: rgb, outHsl: &mTempHsl)
        
        return shouldIgnoreColor(rgb, mTempHsl)
    }
    
    private func shouldIgnoreColor(color: Palette.Swatch) -> Bool {
        return shouldIgnoreColor(color.rgb, color.hsl)
    }
    
    private func shouldIgnoreColor(_ rgb: Int, _ hsl: [Float]) -> Bool {
        guard let mFilters = mFilters, mFilters.count > 0 else {
            return false
        }
        
        for filter in mFilters {
            if (!filter.isAllowed(rgb, hsl)) {
                return true
            }
        }
        return false
    }
    
    /**
     * Quantized a RGB888 value to have a word width of {@value #QUANTIZE_WORD_WIDTH}.
     */
    private static func quantizeFromRgb888(_ color: Int) -> Int {
        let r = modifyWordWidth(Color.red(color), 8, QUANTIZE_WORD_WIDTH)
        let g = modifyWordWidth(Color.green(color), 8, QUANTIZE_WORD_WIDTH)
        let b = modifyWordWidth(Color.blue(color), 8, QUANTIZE_WORD_WIDTH)
        return r << (QUANTIZE_WORD_WIDTH + QUANTIZE_WORD_WIDTH) | g << QUANTIZE_WORD_WIDTH | b
    }
    
    /**
     * Quantized RGB888 values to have a word width of {@value #QUANTIZE_WORD_WIDTH}.
     */
    static func approximateToRgb888(r: Int, g: Int, b: Int) -> Int {
        return Color.rgb(red: modifyWordWidth(r, QUANTIZE_WORD_WIDTH, 8),
                         green: modifyWordWidth(g, QUANTIZE_WORD_WIDTH, 8),
                         blue: modifyWordWidth(b, QUANTIZE_WORD_WIDTH, 8))
    }
    
    private static func approximateToRgb888(_ color: Int) -> Int {
        return approximateToRgb888(r: quantizedRed(color),
                                   g: quantizedGreen(color),
                                   b: quantizedBlue(color))
    }
    
    /**
     * @return red component of the quantized color
     */
    static func quantizedRed(_ color: Int) -> Int {
        return (color >> (QUANTIZE_WORD_WIDTH + QUANTIZE_WORD_WIDTH)) & QUANTIZE_WORD_MASK
    }
    
    /**
     * @return green component of a quantized color
     */
    static func quantizedGreen(_ color: Int) -> Int {
        return (color >> QUANTIZE_WORD_WIDTH) & QUANTIZE_WORD_MASK
    }
    
    /**
     * @return blue component of a quantized color
     */
    static func quantizedBlue(_ color: Int) -> Int {
        return color & QUANTIZE_WORD_MASK
    }
    
    private static func modifyWordWidth(_ value: Int, _ currentWidth: Int, _ targetWidth: Int) -> Int {
        var newValue: Int
        if (targetWidth > currentWidth) {
            // If we're approximating up in word width, we'll shift up
            newValue = value << (targetWidth - currentWidth)
        } else {
            // Else, we will just shift and keep the MSB
            newValue = value >> (currentWidth - targetWidth)
        }
        return newValue & ((1 << targetWidth) - 1)
    }
}

extension ColorCutQuantizer {
    
    /**
     * Represents a tightly fitting box around a color space.
     */
    private class Vbox: Comparable {
        
        static func < (lhs: ColorCutQuantizer.Vbox, rhs: ColorCutQuantizer.Vbox) -> Bool {
            return rhs.getVolume() - lhs.getVolume() > 0
        }
        
        static func == (lhs: ColorCutQuantizer.Vbox, rhs: ColorCutQuantizer.Vbox) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
        private let colorCutQuantizer: ColorCutQuantizer
        
        // lower and upper index are inclusive
        private let mLowerIndex: Int
        private var mUpperIndex: Int
        
        // Population of colors within this box
        private var mPopulation: Int
        
        private var mMinRed, mMaxRed: Int
        private var mMinGreen, mMaxGreen: Int
        private var mMinBlue, mMaxBlue: Int
        
        private static var ordinal = Int32(0)
        let hashValue = Int(OSAtomicIncrement32(&Vbox.ordinal))
        
        init(colorCutQuantizer: ColorCutQuantizer, lowerIndex: Int, upperIndex: Int){
            self.colorCutQuantizer = colorCutQuantizer
            mLowerIndex = lowerIndex
            mUpperIndex = upperIndex
            mPopulation = 0
            mMinRed = 0
            mMaxRed = 0
            mMinGreen = 0
            mMaxGreen = 0
            mMinBlue = 0
            mMaxBlue = 0
            fitBox()
        }
        
        final func getVolume() -> Int {
            return (mMaxRed - mMinRed + 1) * (mMaxGreen - mMinGreen + 1) * (mMaxBlue - mMinBlue + 1)
        }
        
        final func canSplit() -> Bool {
            return getColorCount() > 1
        }
        
        final func getColorCount() -> Int{
            return 1 + mUpperIndex - mLowerIndex
        }
        
        /**
         * Recomputes the boundaries of this box to tightly fit the colors within the box.
         */
        final func fitBox() {
            let colors = colorCutQuantizer.mColors
            let hist = colorCutQuantizer.mHistogram
            
            // Reset the min and max to opposite values
            var minRed = Int.max, minGreen = Int.max, minBlue = Int.max
            var maxRed = Int.min, maxGreen = Int.min, maxBlue = Int.min
            var count = 0
            
            for i in stride(from: mLowerIndex, through: mUpperIndex, by: 1) {
                let color = colors[i]
                count += hist[color]
                
                let r = quantizedRed(color)
                let g = quantizedGreen(color)
                let b = quantizedBlue(color)
                if (r > maxRed) {
                    maxRed = r
                }
                if (r < minRed) {
                    minRed = r
                }
                if (g > maxGreen) {
                    maxGreen = g
                }
                if (g < minGreen) {
                    minGreen = g
                }
                if (b > maxBlue) {
                    maxBlue = b
                }
                if (b < minBlue) {
                    minBlue = b
                }
            }
            
            mMinRed = minRed
            mMaxRed = maxRed
            mMinGreen = minGreen
            mMaxGreen = maxGreen
            mMinBlue = minBlue
            mMaxBlue = maxBlue
            mPopulation = count
        }
        
        /**
         * Split this color box at the mid-point along its longest dimension
         *
         * @return the new ColorBox
         */
        final func splitBox() -> Vbox {
            if (!canSplit()) {
                // throw new IllegalStateException("Can not split a box with only 1 color")
                assertionFailure("Can not split a box with only 1 color")
            }
            
            // find median along the longest dimension
            let splitPoint = findSplitPoint()
            
            let newBox = Vbox(colorCutQuantizer: colorCutQuantizer,
                              lowerIndex: splitPoint + 1,
                              upperIndex: mUpperIndex)
            
            // Now change this box's upperIndex and recompute the color boundaries
            mUpperIndex = splitPoint
            fitBox()
            
            return newBox
        }
        
        /**
         * @return the dimension which this box is largest in
         */
        final func getLongestColorDimension() -> Int {
            let redLength = mMaxRed - mMinRed
            let greenLength = mMaxGreen - mMinGreen
            let blueLength = mMaxBlue - mMinBlue
            
            if (redLength >= greenLength && redLength >= blueLength) {
                return COMPONENT_RED
            } else if (greenLength >= redLength && greenLength >= blueLength) {
                return COMPONENT_GREEN
            } else {
                return COMPONENT_BLUE
            }
        }
        
        /**
         * Finds the point within this box's lowerIndex and upperIndex index of where to split.
         *
         * This is calculated by finding the longest color dimension, and then sorting the
         * sub-array based on that dimension value in each color. The colors are then iterated over
         * until a color is found with at least the midpoint of the whole box's dimension midpoint.
         *
         * @return the index of the colors array to split from
         */
        final func findSplitPoint() -> Int {
            let longestDimension = getLongestColorDimension()
            let hist = colorCutQuantizer.mHistogram
            var colors = colorCutQuantizer.mColors
            
            // We need to sort the colors in this box based on the longest color dimension.
            // As we can't use a Comparator to define the sort logic, we modify each color so that
            // its most significant is the desired dimension
            modifySignificantOctet(&colors, longestDimension, mLowerIndex, mUpperIndex)
            
            // Now sort... Arrays.sort uses a exclusive toIndex so we need to add 1
            // Arrays.sort(colors, mLowerIndex, mUpperIndex + 1)
            colors[mLowerIndex...mUpperIndex].sort()
            
            // Now revert all of the colors so that they are packed as RGB again
            modifySignificantOctet(&colors, longestDimension, mLowerIndex, mUpperIndex)
            
            let midPoint = mPopulation / 2
            
            var count = 0
            for i in mLowerIndex...mUpperIndex {
                count += hist[colors[i]]
                if (count >= midPoint) {
                    // we never want to split on the upperIndex, as this will result in the same
                    // box
                    return min(mUpperIndex - 1, i)
                }
            }
            
            return mLowerIndex
        }
        
        /**
         * @return the average color of this box.
         */
        final func getAverageColor() -> Palette.Swatch {
            let colors = colorCutQuantizer.mColors
            let hist = colorCutQuantizer.mHistogram
            var redSum = 0
            var greenSum = 0
            var blueSum = 0
            var totalPopulation = 0
            
            for i in mLowerIndex...mUpperIndex {
                let color = colors[i]
                let colorPopulation = hist[color]
                
                totalPopulation += colorPopulation
                redSum += colorPopulation * quantizedRed(color)
                greenSum += colorPopulation * quantizedGreen(color)
                blueSum += colorPopulation * quantizedBlue(color)
            }
            
            let redMean = Int(round(Float(redSum) / Float(totalPopulation)))
            let greenMean = Int(round(Float(greenSum) / Float(totalPopulation)))
            let blueMean = Int(round(Float(blueSum) / Float(totalPopulation)))
            
            let color = approximateToRgb888(r: redMean, g: greenMean, b: blueMean)
            return Palette.Swatch(color: color, population: totalPopulation)
        }
    }
}
