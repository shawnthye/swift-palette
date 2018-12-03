//
//  Palette.swift
//  Palette
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

public final class Palette {
    
    public typealias Filter = PaletteFilter
    
    static let defaultResizeBitmapArea = 112 * 112
    static let defaultCalculateNumberColors = 16
    
    static let minContrastTitleText: Float = 3.0
    static let minContrastBodyText: Float = 4.5
    
    public let swatches: [Swatch]
    public let targets: [Target]
    
    private var mSelectedSwatches: [Target : Swatch]
    private var mUsedColors: [ColorInt: Bool]
    
    private var dominantSwatch: Swatch?
    
    /**
     * Start generating a {@link Palette} with the returned {@link Builder} instance.
     */
    public static func from(bitmap: CGImage) -> Builder {
       return Builder(bitmap: bitmap)
    }
    
    init(swatches: [Swatch], targets: [Target]) {
        self.swatches = swatches
        self.targets = targets
        
        mUsedColors = [:]
        mSelectedSwatches = [:]
        
        dominantSwatch = findDominantSwatch()
    }
    
    /**
     * Returns the most vibrant swatch in the palette. Might be null.
     *
     * @see Target#VIBRANT
     */
    public var vibrantSwatch: Swatch? {
        get { return getSwatchForTarget(Target.VIBRANT) }
    }
    
    /**
     * Returns a light and vibrant swatch from the palette. Might be null.
     *
     * @see Target#LIGHT_VIBRANT
     */
    public var lightVibrantSwatch: Swatch? {
        get { return getSwatchForTarget(Target.LIGHT_VIBRANT) }
    }
    
    /**
     * Returns a dark and vibrant swatch from the palette. Might be null.
     *
     * @see Target#DARK_VIBRANT
     */
    public var darkVibrantSwatch: Swatch? {
        get { return getSwatchForTarget(Target.DARK_VIBRANT) }
    }
    
    /**
     * Returns a muted swatch from the palette. Might be null.
     *
     * @see Target#MUTED
     */
    public var mutedSwatch: Swatch? {
        get { return getSwatchForTarget(Target.MUTED) }
    }
    
    /**
     * Returns a muted and light swatch from the palette. Might be null.
     *
     * @see Target#LIGHT_MUTED
     */
    public var lightMutedSwatch: Swatch? {
        get { return getSwatchForTarget(Target.LIGHT_MUTED) }
    }
    
    /**
     * Returns a muted and dark swatch from the palette. Might be null.
     *
     * @see Target#DARK_MUTED
     */
    public var darkMutedSwatch: Swatch? {
        get { return getSwatchForTarget(Target.DARK_MUTED) }
    }
    
    /**
     * Returns the selected swatch for the given target from the palette, or {@code null} if one
     * could not be found.
     */
    public func getSwatchForTarget(_ target: Target) -> Swatch? {
        return mSelectedSwatches[target]
    }
    
    func generate() {
        // We need to make sure that the scored targets are generated first. This is so that
        // inherited targets have something to inherit from
        for target in targets {
            target.normalizeWeights()
            mSelectedSwatches[target] = generateScoredTarget(target)
        }
        // We now clear out the used colors
        mUsedColors.removeAll()
    }
    
    private func generateScoredTarget(_ target: Target) -> Swatch? {
        let maxScoreSwatch = getMaxScoredSwatchForTarget(target)
        if let maxScoreSwatch = maxScoreSwatch, target.exclusive {
            // If we have a swatch, and the target is exclusive, add the color to the used list
            mUsedColors[maxScoreSwatch.rgb] = true
        }
        return maxScoreSwatch
    }
    
    private func getMaxScoredSwatchForTarget(_ target: Target) -> Swatch? {
        var maxScore: Float = 0
        var maxScoreSwatch: Swatch?
        for swatch in swatches {
            if (shouldBeScoredForTarget(swatch, target)) {
                let score = generateScore(swatch, target)
                if (maxScoreSwatch == nil || score > maxScore) {
                    maxScoreSwatch = swatch
                    maxScore = score
                }
            }
        }
        return maxScoreSwatch
    }
    
    private func shouldBeScoredForTarget(_ swatch: Swatch, _ target: Target) -> Bool {
        // Check whether the HSL values are within the correct ranges, and this color hasn't
        // been used yet.
        let hsl = swatch.hsl
        return hsl[1] >= target.minimumSaturation && hsl[1] <= target.maximumSaturation
            && hsl[2] >= target.minimumLightness && hsl[2] <= target.maximumLightness
            && !(mUsedColors[swatch.rgb] ?? false)
    }
    
    private func generateScore(_ swatch: Swatch, _ target: Target) -> Float {
        let hsl = swatch.hsl
        
        var saturationScore: Float = 0
        var luminanceScore: Float = 0
        var populationScore: Float = 0
        
        let maxPopulation = dominantSwatch?.population ?? 1
        
        if target.saturationWeight > 0 {
            saturationScore = target.saturationWeight
                * (1 - abs(hsl[1] - target.targetSaturation))
        }
        if target.lightnessWeight > 0 {
            luminanceScore = target.lightnessWeight
                * (1 - abs(hsl[2] - target.targetLightness))
        }
        if target.populationWeight > 0 {
            populationScore = target.populationWeight
                * (Float(swatch.population) / Float(maxPopulation))
        }
        
        return saturationScore + luminanceScore + populationScore
    }
    
    private func findDominantSwatch() -> Swatch? {
        var maxSwatch: Swatch?
        for swatch in swatches {
            if swatch.population > maxSwatch?.population ?? Int.min {
                maxSwatch = swatch
            }
        }
        return maxSwatch
    }
}

extension Palette {
    
    /**
     * Builder class for generating `Palette` instances.
     */
    public final class Builder {
        
        private let mSwatches: [Swatch]?
        private let mBitmap: CGImage?
        
        private var mTargets: [Target] = []
        
        private var mMaxColors = Palette.defaultCalculateNumberColors
        private var mResizeArea = Palette.defaultResizeBitmapArea
        private var mResizeMaxDimension = -1
        
        private var mFilters: [Filter] = []
        private var mRegion: CGRect?
        
        /**
         * Construct a new {@link Builder} using a source {@link Bitmap}
         */
        public init(bitmap: CGImage) {
            mFilters.append(Palette.defaultFilter)
            mBitmap = bitmap
            mSwatches = nil
            
            // Add the default targets
            mTargets.append(Target.LIGHT_VIBRANT)
            mTargets.append(Target.VIBRANT)
            mTargets.append(Target.DARK_VIBRANT)
            mTargets.append(Target.LIGHT_MUTED)
            mTargets.append(Target.MUTED)
            mTargets.append(Target.DARK_MUTED)
        }
        
        /**
         * Construct a new {@link Builder} using a list of {@link Swatch} instances.
         * Typically only used for testing.
         */
        public init(swatches: [Swatch]) {
            if swatches.isEmpty {
                assertionFailure("List of Swatches is not valid")
                // throw new IllegalArgumentException("List of Swatches is not valid")
            }
            mFilters.append(Palette.defaultFilter)
            mSwatches = swatches
            mBitmap = nil
        }
        
        /**
         * Set the maximum number of colors to use in the quantization step when using a
         * {@link android.graphics.Bitmap} as the source.
         * <p>
         * Good values for depend on the source image type. For landscapes, good values are in
         * the range 10-16. For images which are largely made up of people's faces then this
         * value should be increased to ~24.
         */
        public func maximumColorCount(colors: Int) -> Builder {
            mMaxColors = colors
            return self
        }
        
        /**
         * Set the resize value when using a {@link android.graphics.Bitmap} as the source.
         * If the bitmap's area is greater than the value specified, then the bitmap
         * will be resized so that its area matches {@code area}. If the
         * bitmap is smaller or equal, the original is used as-is.
         * <p>
         * This value has a large effect on the processing time. The larger the resized image is,
         * the greater time it will take to generate the palette. The smaller the image is, the
         * more detail is lost in the resulting image and thus less precision for color selection.
         *
         * @param area the number of pixels that the intermediary scaled down Bitmap should cover,
         *             or any value <= 0 to disable resizing.
         */
        public func resizeBitmapArea(area: Int) -> Builder {
            mResizeArea = area
            mResizeMaxDimension = -1
            return self
        }
        
        /**
         * Clear all added filters. This includes any default filters added automatically by
         * {@link Palette}.
         */
        public func clearFilters() -> Builder {
            mFilters.removeAll()
            return self
        }
        
        /**
         * Add a filter to be able to have fine grained control over which colors are
         * allowed in the resulting palette.
         *
         * @param filter filter to add.
         */
        public func addFilter(filter: Filter) -> Builder {
            mFilters.append(filter)
            return self
        }
        
        /**
         * Set a region of the bitmap to be used exclusively when calculating the palette.
         * <p>This only works when the original input is a {@link Bitmap}.</p>
         *
         * @param left The left side of the rectangle used for the region.
         * @param top The top of the rectangle used for the region.
         * @param right The right side of the rectangle used for the region.
         * @param bottom The bottom of the rectangle used for the region.
         */
        public func setRegion(left: Int, top: Int, right: Int, bottom: Int) -> Builder {
            guard let bitmap = mBitmap else {
                return self
            }
            
            // Set the Rect to be initially the whole Bitmap if null
            let region = mRegion ?? CGRect(x: 0, y: 0, width: bitmap.width, height: bitmap.height)
            // Now just get the intersection with the region
            if !region.intersects(Rect(left: left, top: top, right: right, bottom: bottom)) {
                assertionFailure("The given region must intersect with "
                    + "the Bitmap's dimensions.")
                // throw new IllegalArgumentException("The given region must intersect with "
                //     + "the Bitmap's dimensions.")
            }
            return self
        }
        
        /**
         * Clear any previously region set via {@link #setRegion(int, int, int, int)}.
         */
        public func clearRegion() -> Builder {
            mRegion = nil
            return self
        }
        
        /**
         * Add a target profile to be generated in the palette.
         *
         * <p>You can retrieve the result via {@link Palette#getSwatchForTarget(Target)}.</p>
         */
        public func addTarget(target: Target) -> Builder {
            if (!mTargets.contains(target)) {
                mTargets.append(target)
            }
            return self
        }
        
        /**
         * Clear all added targets. This includes any default targets added automatically by
         * {@link Palette}.
         */
        public func clearTargets() -> Builder {
            mTargets.removeAll()
            return self
        }
        
        /**
         * Generate and return the {@link Palette} synchronously.
         */
        public func generate() -> Palette {
            
            let swatches: [Swatch]
            
            if let originalBitmap = mBitmap {
                // We have a Bitmap so we need to use quantization to reduce the number of colors
                
                // First we'll scale down the bitmap if needed
                let bitmap = scaleBitmapDown(originalBitmap)
                
                // LOG: Processed Bitmap
                
                if var region = mRegion, bitmap != originalBitmap {
                    // If we have a scaled bitmap and a selected region, we need to scale down the
                    // region to match the new scale
                    let scale = Double(bitmap.width) / Double(originalBitmap.width)
                    region.left = Int(floor(Double(region.left) * scale))
                    region.top = Int(floor(Double(region.top) * scale))
                    region.right = min(Int(ceil(Double(region.right) * scale)), bitmap.width)
                    region.bottom = min(Int(ceil(Double(region.bottom) * scale)), bitmap.height)
                }
                
                
                // Now generate a quantizer from the Bitmap
                let quantizer = ColorCutQuantizer(
                    pixels: getPixelsFromBitmap(bitmap),
                    maxColors: mMaxColors,
                    filters: mFilters.isEmpty ? nil : mFilters)
                
                swatches = quantizer.quantizedColors
                
                // LOG: Color quantization completed
            } else {
                // Else we're using the provided swatches
                swatches = mSwatches ?? []
            }
            
            // Now create a Palette instance
            let p = Palette(swatches: swatches, targets: mTargets)
            // And make it generate itself
            p.generate()
            
            // LOG: Created Palette
            
            return p
        }
        
        /**
         * Generate the {@link Palette} asynchronously. The provided listener's
         * {@link PaletteAsyncListener#onGenerated} method will be called with the palette when
         * generated.
         *  - Parameter callBack: callBack
         */
        public func generate(_ async: ((Palette) -> Void)?) {
            DispatchQueue.global(qos: .default).async {
                let p = self.generate()
                DispatchQueue.main.async {
                    async?(p)
                }
            }
        }
        
        private func getPixelsFromBitmap(_ bitmap: CGImage) -> [Int] {
            let bitmapWidth = bitmap.width
            let bitmapHeight = bitmap.height
            var pixels = [ColorInt](repeating: 0, count: bitmapWidth * bitmapHeight)
            pixels.reserveCapacity(bitmapWidth * bitmapHeight)
            bitmap.getPixels(pixels: &pixels)
            
            guard let region = mRegion else {
                // If we don't have a region, return all of the pixels
                return pixels
            }
            
            // If we do have a region, lets create a subset array containing only the region's
            // pixels
            let regionWidth = Int(region.width)
            let regionHeight = Int(region.height)
            // pixels contains all of the pixels, so we need to iterate through each row and
            // copy the regions pixels into a new smaller array
            var subsetPixels = [Int]()
            subsetPixels.reserveCapacity(regionWidth * regionHeight)
            for row in 0..<regionHeight {
                let startPos = row * regionWidth
                let endPos = startPos + regionWidth
                subsetPixels[startPos..<endPos] = pixels[startPos..<endPos]
            }
            return subsetPixels
        }
        
        /**
         * Scale the bitmap down as needed.
         */
        private func scaleBitmapDown(_ bitmap: CGImage) -> CGImage {
            var scaleRatio: Double = -1
            
            if (mResizeArea > 0) {
                let bitmapArea = bitmap.width * bitmap.height
                if (bitmapArea > mResizeArea) {
                    scaleRatio = sqrt(Double(mResizeArea) / Double(bitmapArea))
                }
            } else if (mResizeMaxDimension > 0) {
                let maxDimension = max(bitmap.width, bitmap.height)
                if (maxDimension > mResizeMaxDimension) {
                    scaleRatio = Double(mResizeMaxDimension) / Double(maxDimension)
                }
            }
            
            if (scaleRatio <= 0) {
                // Scaling has been disabled or not needed so just return the Bitmap
                return bitmap
            }
            
            return bitmap.resize(scaleRatio)
        }
    }
}

extension Palette {
    
    /**
     * Represents a color swatch generated from an image's palette. The RGB color can be retrieved
     * by calling {@link #getRgb()}.
     */
    public final class Swatch {
        
        public let red, green, blue: Int
        public let rgb: Int
        public let population: Int
        
        private var generatedTextColors: Bool = false
        
        public var titleTextColor: Int {
            get {
                ensureTextColorsGenerated()
                return _titleTextColor
            }
        }
        private var _titleTextColor = 0
        
        public var bodyTextColor: Int {
            get {
                ensureTextColorsGenerated()
                return _bodyTextColor
            }
        }
        private var _bodyTextColor = 0
        
        /**
         * Return this swatch's HSL values.
         *     hsv[0] is Hue [0 .. 360)
         *     hsv[1] is Saturation [0...1]
         *     hsv[2] is Lightness [0...1]
         */
        public var hsl: [Float] {
            get {
                var hsl = _hsl ?? [Float](repeating: 0, count: 3)
                
                //redundant? why google do this?
                ColorUtils.RGBToHSL(r: red, g: green, b: blue, outHsl: &hsl)
                return hsl
            }
        }
        private var _hsl: [Float]?
        
        init(color: ColorInt, population: Int) {
            red = Color.red(color)
            green = Color.green(color)
            blue = Color.blue(color)
            rgb = color
            self.population = population
        }
        
        init(red: Int, green: Int, blue: Int, population: Int) {
            self.red = red
            self.green = green
            self.blue = blue
            self.rgb = Color.rgb(red: red, green: green, blue: blue)
            self.population = population
        }
        
        convenience init(hsl: [Float], population: Int) {
            self.init(color: ColorUtils.HSLToColor(hsl), population: population)
            self._hsl = hsl
        }
        
        private func ensureTextColorsGenerated() {
            if (!generatedTextColors) {
                // First check white, as most colors will be dark
                let lightBodyAlpha = ColorUtils.calculateMinimumAlpha(
                    foreground: Color.WHITE,
                    background: rgb,
                    minContrastRatio: Palette.minContrastBodyText)
                
                let lightTitleAlpha = ColorUtils.calculateMinimumAlpha(
                    foreground: Color.WHITE,
                    background: rgb,
                    minContrastRatio: Palette.minContrastTitleText)
                
                if (lightBodyAlpha != -1 && lightTitleAlpha != -1) {
                    // If we found valid light values, use them and return
                    _bodyTextColor = ColorUtils.setAlphaComponent(color: Color.WHITE, alpha: lightBodyAlpha)
                    _titleTextColor = ColorUtils.setAlphaComponent(color: Color.WHITE, alpha: lightTitleAlpha)
                    generatedTextColors = true
                    return
                }
                
                let darkBodyAlpha = ColorUtils.calculateMinimumAlpha(
                    foreground: Color.BLACK,
                    background: rgb,
                    minContrastRatio: Palette.minContrastBodyText)
                let darkTitleAlpha = ColorUtils.calculateMinimumAlpha(
                    foreground: Color.BLACK,
                    background: rgb,
                    minContrastRatio: Palette.minContrastTitleText)
                
                if (darkBodyAlpha != -1 && darkTitleAlpha != -1) {
                    // If we found valid dark values, use them and return
                    _bodyTextColor = ColorUtils.setAlphaComponent(color: Color.BLACK, alpha: darkBodyAlpha)
                    _titleTextColor = ColorUtils.setAlphaComponent(color: Color.BLACK, alpha: darkTitleAlpha)
                    generatedTextColors = true
                    return
                }
                
                // If we reach here then we can not find title and body values which use the same
                // lightness, we need to use mismatched values
                _bodyTextColor = lightBodyAlpha != -1
                    ? ColorUtils.setAlphaComponent(color: Color.WHITE, alpha: lightBodyAlpha)
                    : ColorUtils.setAlphaComponent(color: Color.BLACK, alpha: darkBodyAlpha)
                _titleTextColor = lightTitleAlpha != -1
                    ? ColorUtils.setAlphaComponent(color: Color.WHITE, alpha: lightTitleAlpha)
                    : ColorUtils.setAlphaComponent(color: Color.BLACK, alpha: darkTitleAlpha)
                generatedTextColors = true
            }
        }
        
    }
}

extension Palette.Swatch: Hashable {
    
    public static func == (lhs: Palette.Swatch, rhs: Palette.Swatch) -> Bool {
        return lhs.population == rhs.population && lhs.rgb == rhs.rgb
    }
    
    public var hashValue: Int {
        return 31 * rgb + population
    }
}

public protocol PaletteFilter {
    func isAllowed(_ rgb: Int, _ hsl: [Float]) -> Bool
}

extension Palette {
    
    static let defaultFilter = DefaultFilter()
    
    struct DefaultFilter: PaletteFilter {
        
        private static let blackMaxLightness: Float = 0.05
        private static let whiteMinLightness: Float = 0.95
        
        func isAllowed(_ rgb: Int, _ hsl: [Float]) -> Bool {
            return !isWhite(hsl) && !isBlack(hsl) && !isNearRedILine(hsl)
        }
        
        /**
         * @return true if the color represents a color which is close to black.
         */
        private func isBlack(_ hslColor: [Float]) -> Bool {
            return hslColor[2] <= DefaultFilter.blackMaxLightness
        }
        
        /**
         * @return true if the color represents a color which is close to white.
         */
        private func isWhite(_ hslColor: [Float]) -> Bool {
            return hslColor[2] >= DefaultFilter.whiteMinLightness
        }
        
        /**
         * @return true if the color lies close to the red side of the I line.
         */
        private func isNearRedILine(_ hslColor: [Float]) -> Bool {
            return hslColor[0] >= 10.0 && hslColor[0] <= 37.0 && hslColor[1] <= 0.82
        }
    }
}
