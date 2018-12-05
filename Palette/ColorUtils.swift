//
//  ColorUtils.swift
//  Palette
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

final class ColorUtils {
    
    private init() { }
    
    private static let minAlphaSearchMaxIterations = 10
    private static let minAlphaSearchPrecision = 1
    
    private static let threadDictionary = Thread.current.threadDictionary
    private static let threadTempArrayKey = "Palette.ColorUtils.TempDouble3Array"
    
    /**
     * Composite two potentially translucent colors over each other and returns the result.
     */
    public static func compositeColors(foreground: ColorInt, background: ColorInt) -> Int {
        let bgAlpha = Color.alpha(background)
        let fgAlpha = Color.alpha(foreground)
        let a = compositeAlpha(fgAlpha, bgAlpha)
        
        let r = compositeComponent(Color.red(foreground), fgAlpha,
                                   Color.red(background), bgAlpha, a)
        let g = compositeComponent(Color.green(foreground), fgAlpha,
                                   Color.green(background), bgAlpha, a)
        let b = compositeComponent(Color.blue(foreground), fgAlpha,
                                   Color.blue(background), bgAlpha, a)
        
        return Color.argb(alpha: a, red: r, green: g, blue: b)
    }
    
    private static func compositeAlpha(_ foregroundAlpha: Int, _ backgroundAlpha: Int) -> Int {
        return 0xFF - (((0xFF - backgroundAlpha) * (0xFF - foregroundAlpha)) / 0xFF)
    }
    
    private static func compositeComponent(_ fgC: Int, _ fgA: Int, _ bgC: Int, _ bgA: Int, _ a: Int) -> Int {
        if a == 0 {
            return 0
        }
        return ((0xFF * fgC * fgA) + (bgC * bgA * (0xFF - fgA))) / (a * 0xFF)
    }
    
    /**
     * Returns the luminance of a color as a float between {@code 0.0} and {@code 1.0}.
     * <p>Defined as the Y component in the XYZ representation of {@code color}.</p>
     * - @FloatRange(from = 0.0, to = 1.0)
     */
    public static func calculateLuminance(color: ColorInt) -> Double {
        var result = getTempDouble3Array()
        colorToXYZ(color: color, outXyz: &result)
        // Luminance is the Y component
        return result[1] / 100
    }
    
    /**
     * Returns the contrast ratio between {@code foreground} and {@code background}.
     * {@code background} must be opaque.
     * <p>
     * Formula defined
     * <a href="http://www.w3.org/TR/2008/REC-WCAG20-20081211/#contrast-ratiodef">here</a>.
     */
    public static func calculateContrast(foreground: inout ColorInt, background: ColorInt) -> Double {
        if (Color.alpha(background) != 255) {
            //            throw new IllegalArgumentException("background can not be translucent: #" + ColorInt.toHexString(background))
            assertionFailure("background can not be translucent: #\(ColorInt.toHexString(background))")
        }
        if (Color.alpha(foreground) < 255) {
            // If the foreground is translucent, composite the foreground over the background
            foreground = compositeColors(foreground: foreground, background: background)
        }
        
        let luminance1 = calculateLuminance(color: foreground) + 0.05
        let luminance2 = calculateLuminance(color: background) + 0.05
        
        // Now return the lighter luminance divided by the darker luminance
        return max(luminance1, luminance2) / min(luminance1, luminance2)
    }
    
    /**
     * Calculates the minimum alpha value which can be applied to {@code foreground} so that would
     * have a contrast value of at least {@code minContrastRatio} when compared to
     * {@code background}.
     *
     * @param foreground       the foreground color
     * @param background       the opaque background color
     * @param minContrastRatio the minimum contrast ratio
     * @return the alpha value in the range 0-255, or -1 if no value could be calculated
     */
    public static func calculateMinimumAlpha(foreground: ColorInt, background: ColorInt, minContrastRatio: Float) -> Int {
        if (Color.alpha(background) != 255) {
            // throw new IllegalArgumentException("background can not be translucent: #" + Integer.toHexString(background))
            assertionFailure("background can not be translucent: #\(ColorInt.toHexString(background))")
            
        }
        
        // First lets check that a fully opaque foreground has sufficient contrast
        var testForeground = setAlphaComponent(color: foreground, alpha: 255)
        var testRatio = Float(calculateContrast(foreground: &testForeground, background: background))
        if (testRatio < minContrastRatio) {
            // Fully opaque foreground does not have sufficient contrast, return error
            return -1
        }
        
        // Binary search to find a value with the minimum value which provides sufficient contrast
        var numIterations = 0
        var minAlpha = 0
        var maxAlpha = 255
        
        while (numIterations <= minAlphaSearchMaxIterations &&
            (maxAlpha - minAlpha) > minAlphaSearchPrecision) {
                let testAlpha = (minAlpha + maxAlpha) / 2
                
                testForeground = setAlphaComponent(color: foreground, alpha: testAlpha)
                testRatio = Float(calculateContrast(foreground: &testForeground, background: background))
                
                if (testRatio < minContrastRatio) {
                    minAlpha = testAlpha
                } else {
                    maxAlpha = testAlpha
                }
                
                numIterations += 1
        }
        
        // Conservatively return the max of the range of possible alphas, which is known to pass.
        return maxAlpha
    }
    
    /**
     * Convert RGB components to HSL (hue-saturation-lightness).
     * <ul>
     * <li>outHsl[0] is Hue [0 .. 360)</li>
     * <li>outHsl[1] is Saturation [0...1]</li>
     * <li>outHsl[2] is Lightness [0...1]</li>
     * </ul>
     *
     * @param r      red component value [0..255] @IntRange(from = 0x0, to = 0xFF)
     * @param g      green component value [0..255] @IntRange(from = 0x0, to = 0xFF)
     * @param b      blue component value [0..255] @IntRange(from = 0x0, to = 0xFF)
     * @param outHsl 3-element array which holds the resulting HSL components
     */
    public static func RGBToHSL(r: Int, g: Int, b: Int, outHsl: inout [Float]) {
        let rf = Float(r) / 255.0
        let gf = Float(g) / 255.0
        let bf = Float(b) / 255.0
        
        let max = Float.maximum(rf, Float.maximum(gf, bf))
        let min = Float.minimum(rf, Float.minimum(gf, bf))
        let deltaMaxMin = max - min
        
        var h, s: Float
        let l = (max + min) / 2
        
        if (max == min) {
            // Monochromatic
            h = 0
            s = 0
        } else {
            if (max == rf) {
                h = ((gf - bf) / deltaMaxMin).truncatingRemainder(dividingBy: 6.0)
            } else if (max == gf) {
                h = ((bf - rf) / deltaMaxMin) + 2
            } else {
                h = ((rf - gf) / deltaMaxMin) + 4
            }
            
            s = deltaMaxMin / (1 - abs(2 * l - 1))
        }
        
        h = (h * 60).truncatingRemainder(dividingBy: 360.0)
        if h < 0 {
            h += 360
        }
        
        outHsl[0] = constrain(h, 0.0, 360.0)
        outHsl[1] = constrain(s, 0.0, 1.0)
        outHsl[2] = constrain(l, 0.0, 1.0)
    }
    
    /**
     * Convert the ARGB color to its HSL (hue-saturation-lightness) components.
     * <ul>
     * <li>outHsl[0] is Hue [0 .. 360)</li>
     * <li>outHsl[1] is Saturation [0...1]</li>
     * <li>outHsl[2] is Lightness [0...1]</li>
     * </ul>
     *
     * @param color  the ARGB color to convert. The alpha component is ignored
     * @param outHsl 3-element array which holds the resulting HSL components
     */
    public static func colorToHSL(color: ColorInt, outHsl: inout [Float]) {
        RGBToHSL(r: Color.red(color), g: Color.green(color), b: Color.blue(color), outHsl: &outHsl)
    }
    
    /**
     * Convert HSL (hue-saturation-lightness) components to a RGB color.
     * <ul>
     * <li>hsl[0] is Hue [0 .. 360)</li>
     * <li>hsl[1] is Saturation [0...1]</li>
     * <li>hsl[2] is Lightness [0...1]</li>
     * </ul>
     * If hsv values are out of range, they are pinned.
     *
     * @param hsl 3-element array which holds the input HSL components
     * @return the resulting RGB color
     */
    static func HSLToColor(_ hsl: [Float]) -> ColorInt {
        let h = hsl[0]
        let s = hsl[1]
        let l = hsl[2]
        
        let c = (1 - abs(2 * l - 1)) * s
        let m = l - 0.5 * c
        let x = c * (1 - abs((h / Float(60 % 2)) - 1))
        
        let hueSegment = Int(h / 60)
        
        var r = 0, g = 0, b = 0
        
        switch (hueSegment) {
        case 0:
            r = Int(round(255 * (c + m)))
            g = Int(round(255 * (x + m)))
            b = Int(round(255 * m))
            break
        case 1:
            r = Int(round(255 * (x + m)))
            g = Int(round(255 * (c + m)))
            b = Int(round(255 * m))
            break
        case 2:
            r = Int(round(255 * m))
            g = Int(round(255 * (c + m)))
            b = Int(round(255 * (x + m)))
            break
        case 3:
            r = Int(round(255 * m))
            g = Int(round(255 * (x + m)))
            b = Int(round(255 * (c + m)))
            break
        case 4:
            r = Int(round(255 * (x + m)))
            g = Int(round(255 * m))
            b = Int(round(255 * (c + m)))
            break
        case 5, 6:
            r = Int(round(255 * (c + m)))
            g = Int(round(255 * m))
            b = Int(round(255 * (x + m)))
            break
        default:
            break
        }
        
        r = constrain(r, 0, 255)
        g = constrain(g, 0, 255)
        b = constrain(b, 0, 255)
        
        return Color.rgb(red: r, green: g, blue: b)
    }
    
    /**
     * Set the alpha component of {@code color} to be {@code alpha}.
     * - @IntRange(from = 0x0, to = 0xFF)
     */
    public static func setAlphaComponent(color: ColorInt, alpha: Int) -> ColorInt {
        if (alpha < 0 || alpha > 255) {
            // throw new IllegalArgumentException("alpha must be between 0 and 255.")
            assertionFailure("alpha must be between 0 and 255.")
        }
        return (color & 0x00ffffff) | (alpha << 24)
    }
    
    /**
     * Convert the ARGB color to its CIE XYZ representative components.
     *
     * <p>The resulting XYZ representation will use the D65 illuminant and the CIE
     * 2° Standard Observer (1931).</p>
     *
     * <ul>
     * <li>outXyz[0] is X [0 ...95.047)</li>
     * <li>outXyz[1] is Y [0...100)</li>
     * <li>outXyz[2] is Z [0...108.883)</li>
     * </ul>
     *
     * @param color  the ARGB color to convert. The alpha component is ignored
     * @param outXyz 3-element array which holds the resulting LAB components
     */
    public static func colorToXYZ(color: ColorInt, outXyz: inout [Double]) {
        RGBToXYZ(r: Color.red(color),
                 g: Color.green(color),
                 b: Color.blue(color),
                 outXyz: &outXyz)
    }
    
    /**
     * Convert RGB components to its CIE XYZ representative components.
     *
     * <p>The resulting XYZ representation will use the D65 illuminant and the CIE
     * 2° Standard Observer (1931).</p>
     *
     * <ul>
     * <li>outXyz[0] is X [0 ...95.047)</li>
     * <li>outXyz[1] is Y [0...100)</li>
     * <li>outXyz[2] is Z [0...108.883)</li>
     * </ul>
     *
     * @param r      red component value [0..255] @IntRange(from = 0x0, to = 0xFF)
     * @param g      green component value [0..255] @IntRange(from = 0x0, to = 0xFF)
     * @param b      blue component value [0..255] @IntRange(from = 0x0, to = 0xFF)
     * @param outXyz 3-element array which holds the resulting XYZ components
     */
    public static func RGBToXYZ(r: Int, g: Int, b: Int, outXyz: inout [Double]) {
        if (outXyz.count != 3) {
            // throw new IllegalArgumentException("outXyz must have a length of 3.")
            assertionFailure("outXyz must have a length of 3.")
        }
        
        var sr = Double(r) / 255.0
        sr = sr < 0.04045 ? sr / 12.92 : pow((sr + 0.055) / 1.055, 2.4)
        var sg = Double(g) / 255.0
        sg = sg < 0.04045 ? sg / 12.92 : pow((sg + 0.055) / 1.055, 2.4)
        var sb = Double(b) / 255.0
        sb = sb < 0.04045 ? sb / 12.92 : pow((sb + 0.055) / 1.055, 2.4)
        
        outXyz[0] = 100 * (sr * 0.4124 + sg * 0.3576 + sb * 0.1805)
        outXyz[1] = 100 * (sr * 0.2126 + sg * 0.7152 + sb * 0.0722)
        outXyz[2] = 100 * (sr * 0.0193 + sg * 0.1192 + sb * 0.9505)
    }
    
    private static func constrain(_ amount: Float, _ low: Float, _ high: Float) -> Float {
        return amount < low ? low : (amount > high ? high : amount)
    }
    
    private static func constrain(_ amount: Int, _ low: Int, _ high: Int) -> Int {
        return amount < low ? low : (amount > high ? high : amount)
    }
    
    private static func getTempDouble3Array() -> [Double] {
        guard let result = threadDictionary[threadTempArrayKey] as? [Double] else {
            let newResult = [Double](repeating: 0, count: 3)
            threadDictionary[threadTempArrayKey] = newResult
            return newResult
        }
        return result
    }
}

extension Color {
    public var rgbHexadecimal: String? {
        
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Int(components[0] * 255.0 + 0.5) << 16
        let g = Int(components[1] * 255.0 + 0.5) << 8
        let b = Int(components[2] * 255.0 + 0.5)
        let rgb = r | g | b
        
        return ColorInt.toRgbHexadecimal(rgb)
    }
}

extension ColorInt {
    public static func toHexString(_ i: Int) -> String {
        return String(format: "%08X", Int(bitPattern: 0xFFFFFFFF) & i)
    }
    
    public static func toRgbHexadecimal(_ i: Int) -> String {
        return String(format: "%06X", Int(bitPattern: 0xFFFFFF) & i)
    }
}

