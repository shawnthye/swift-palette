//
//  Color.swift
//  Palette
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

/**
 * <h4>Decoding</h4>
 * <p>The four ARGB components can be individually extracted from a color int
 * using the following expressions:</p>
 * <pre class="prettyprint">
 * int A = (color >> 24) & 0xff // or color >>> 24
 * int R = (color >> 16) & 0xff
 * int G = (color >>  8) & 0xff
 * int B = (color      ) & 0xff
 * </pre>
 */
extension Color {
    
    public static let BLACK: ColorInt = 0xFF000000
    public static let WHITE: ColorInt = 0xFFFFFFFF
    
    /**
     * Return the alpha component of a color int. This is the same as saying
     * color >>> 24
     *
     * swift has unsigned integer, but not java
     * https://stackoverflow.com/questions/41202147/unsigned-right-shift-operator-in-swift?rq=1
     * - @IntRange(from = 0, to = 255)
     */
    public static let alpha = {(color:Int) -> Int in (color >> 24) & 0xFF }
    
    /**
     * Return the red component of a color int. This is the same as saying
     * (color >> 16) & 0xFF
     * - @IntRange(from = 0, to = 255)
     */
    public static func red(_ color: Int) -> Int {
        return (color >> 16) & 0xFF
    }
    
    /**
     * Return the green component of a color int. This is the same as saying
     * (color >> 8) & 0xFF
     * - @IntRange(from = 0, to = 255)
     */
    public static func green(_ color: Int) -> Int {
        return (color >> 8) & 0xFF
    }
    
    /**
     * Return the blue component of a color int. This is the same as saying
     * color & 0xFF
     * - @IntRange(from = 0, to = 255)
     */
    public static func blue(_ color: Int) -> Int {
        return color & 0xFF
    }
    
    /**
     * Return a color-int from red, green, blue components.
     * The alpha component is implicitly 255 (fully opaque).
     * These component values should be \([0..255]\), but there is no
     * range check performed, so if they are out of range, the
     * returned color is undefined.
     *
     * - Parameters:
     *   - red: Red component \([0..255]\) of the color
     *   - green: Green component \([0..255]\) of the color
     *   - blue: Blue component \([0..255]\) of the color
     */
    public static func rgb(red: Int, green: Int, blue: Int) -> ColorInt {
        return 0xff000000 | (red << 16) | (green << 8) | blue
    }
    
    /**
     * Return a color-int from alpha, red, green, blue components.
     * These component values should be \([0..255]\), but there is no
     * range check performed, so if they are out of range, the
     * returned color is undefined.
     * @param alpha Alpha component \([0..255]\) of the color @IntRange(from = 0, to = 255)
     * @param red Red component \([0..255]\) of the color @IntRange(from = 0, to = 255)
     * @param green Green component \([0..255]\) of the color @IntRange(from = 0, to = 255)
     * @param blue Blue component \([0..255]\) of the color @IntRange(from = 0, to = 255)
     */
    public static func argb(alpha: Int, red: Int, green: Int, blue: Int) -> ColorInt {
        return (alpha << 24) | (red << 16) | (green << 8) | blue
    }
}
