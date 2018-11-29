//
//  Target.swift
//  Palette
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

/**
 * A class which allows custom selection of colors in a {@link Palette}'s generation. Instances
 * can be created via the {@link Builder} class.
 *
 * <p>To use the target, use the {@link Palette.Builder#addTarget(Target)} API when building a
 * Palette.</p>
 */
public final class Target {
    private static let TARGET_DARK_LUMA: Float = 0.26
    private static let MAX_DARK_LUMA: Float = 0.45
    
    private static let MIN_LIGHT_LUMA: Float = 0.55
    private static let TARGET_LIGHT_LUMA: Float = 0.74
    
    private static let MIN_NORMAL_LUMA: Float = 0.3
    private static let TARGET_NORMAL_LUMA: Float = 0.5
    private static let MAX_NORMAL_LUMA: Float = 0.7
    
    private static let TARGET_MUTED_SATURATION: Float = 0.3
    private static let MAX_MUTED_SATURATION: Float = 0.4
    
    private static let TARGET_VIBRANT_SATURATION: Float = 1
    private static let MIN_VIBRANT_SATURATION: Float = 0.35
    
    private static let WEIGHT_SATURATION: Float = 0.24
    private static let WEIGHT_LUMA: Float = 0.52
    private static let WEIGHT_POPULATION: Float = 0.24
    
    static let INDEX_MIN: Int = 0
    static let INDEX_TARGET: Int = 1
    static let INDEX_MAX: Int = 2
    
    static let INDEX_WEIGHT_SAT: Int = 0
    static let INDEX_WEIGHT_LUMA: Int = 1
    static let INDEX_WEIGHT_POP: Int = 2
    
    /**
     * A target which has the characteristics of a vibrant color which is light in luminance.
     */
    public static let LIGHT_VIBRANT: Target = {
        setDefaultLightLightnessValues($0)
        setDefaultVibrantSaturationValues($0)
        return $0
    }(Target())
    
    /**
     * A target which has the characteristics of a vibrant color which is neither light or dark.
     */
    public static let VIBRANT: Target = {
        setDefaultNormalLightnessValues($0)
        setDefaultVibrantSaturationValues($0)
        return $0
    }(Target())
    
    /**
     * A target which has the characteristics of a vibrant color which is dark in luminance.
     */
    public static let DARK_VIBRANT: Target = {
        setDefaultDarkLightnessValues($0)
        setDefaultVibrantSaturationValues($0)
        return $0
    }(Target())
    
    /**
     * A target which has the characteristics of a muted color which is light in luminance.
     */
    public static let LIGHT_MUTED: Target = {
        setDefaultLightLightnessValues($0)
        setDefaultMutedSaturationValues($0)
        return $0
    }(Target())
    
    /**
     * A target which has the characteristics of a muted color which is neither light or dark.
     */
    public static let MUTED: Target = {
        setDefaultNormalLightnessValues($0)
        setDefaultMutedSaturationValues($0)
        return $0
    }(Target())
    
    /**
     * A target which has the characteristics of a muted color which is dark in luminance.
     */
    public static let DARK_MUTED: Target = {
        setDefaultDarkLightnessValues($0)
        setDefaultMutedSaturationValues($0)
        return $0
    }(Target())
    
    private final var saturationTargets = [Float](repeating: 0, count: 3)
    private final var lightnessTargets = [Float](repeating: 0, count: 3)
    private final var weights = [Float](repeating: 0, count: 3)
    
    private var isExclusive = true // default to true
    
    required init() {
        
        Target.setTargetDefaultValues(&saturationTargets)
        Target.setTargetDefaultValues(&lightnessTargets)
    }
    
    required init(from: Target) {
        saturationTargets = [Float](from.saturationTargets)
        lightnessTargets = [Float](from.lightnessTargets)
        weights = [Float](from.weights)
    }
    /**
     * The minimum saturation value for this target.
     * - @FloatRange(from = 0, to = 1)
     */
    public var minimumSaturation: Float {
        get { return saturationTargets[Target.INDEX_MIN] }
    }
    
    /**
     * The target saturation value for this target.
     * - @FloatRange(from = 0, to = 1)
     */
    public var targetSaturation: Float {
        get { return saturationTargets[Target.INDEX_TARGET] }
    }
    
    /**
     * The maximum saturation value for this target.
     * - @FloatRange(from = 0, to = 1)
     */
    public var maximumSaturation: Float {
        get { return saturationTargets[Target.INDEX_MAX] }
    }
    
    /**
     * The minimum lightness value for this target.
     * - @FloatRange(from = 0, to = 1)
     */
    public var minimumLightness: Float {
        get { return lightnessTargets[Target.INDEX_MIN] }
    }
    
    /**
     * The target lightness value for this target.
     * - @FloatRange(from = 0, to = 1)
     */
    public var targetLightness: Float {
        get { return lightnessTargets[Target.INDEX_TARGET] }
    }
    
    /**
     * The maximum lightness value for this target.
     * - @FloatRange(from = 0, to = 1)
     */
    public var maximumLightness: Float {
        get { return lightnessTargets[Target.INDEX_MAX] }
    }
    
    /**
     * Returns the weight of importance that this target places on a color's saturation within
     * the image.
     *
     * <p>The larger the weight, relative to the other weights, the more important that a color
     * being close to the target value has on selection.</p>
     *
     * - see `Target#targetSaturation`
     */
    public var saturationWeight: Float {
        get { return weights[Target.INDEX_WEIGHT_SAT] }
    }
    
    /**
     * Returns the weight of importance that this target places on a color's lightness within
     * the image.
     *
     * <p>The larger the weight, relative to the other weights, the more important that a color
     * being close to the target value has on selection.</p>
     *
     * - see `Target#targetLightness`
     */
    public var lightnessWeight: Float {
        get { return weights[Target.INDEX_WEIGHT_LUMA] }
    }
    
    /**
     * Returns the weight of importance that this target places on a color's population within
     * the image.
     *
     * - The larger the weight, relative to the other weights, the more important that a
     * color's population being close to the most populous has on selection.</p>
     */
    public var populationWeight: Float {
        get { return weights[Target.INDEX_WEIGHT_POP] }
    }
    
    /**
     * Returns whether any color selected for this target is exclusive for this target only.
     *
     * If **false**, then the color can be selected for other targets.
     */
    public var exclusive: Bool {
        get { return isExclusive }
    }
    
    private static func setTargetDefaultValues(_ values: inout [Float]) {
        values[INDEX_MIN] = 0
        values[INDEX_TARGET] = 0.5
        values[INDEX_MAX] = 1
    }
    
    private func setDefaultWeights() {
        weights[Target.INDEX_WEIGHT_SAT] = Target.WEIGHT_SATURATION
        weights[Target.INDEX_WEIGHT_LUMA] = Target.WEIGHT_LUMA
        weights[Target.INDEX_WEIGHT_POP] = Target.WEIGHT_POPULATION
    }
    
    func normalizeWeights() {
        var sum: Float = 0
        for i in 0..<weights.count {
            let weight = weights[i]
            if weight > 0 {
                sum += weight
            }
        }
        if sum != 0 {
            for i in 0..<weights.count {
                if weights[i] > 0 {
                    weights[i] /= sum
                }
            }
        }
    }
    
    private static func setDefaultDarkLightnessValues(_ target: Target) {
        target.lightnessTargets[INDEX_TARGET] = TARGET_DARK_LUMA
        target.lightnessTargets[INDEX_MAX] = MAX_DARK_LUMA
    }
    
    private static func setDefaultNormalLightnessValues(_ target: Target) {
        target.lightnessTargets[INDEX_MIN] = MIN_NORMAL_LUMA
        target.lightnessTargets[INDEX_TARGET] = TARGET_NORMAL_LUMA
        target.lightnessTargets[INDEX_MAX] = MAX_NORMAL_LUMA
    }
    
    private static func setDefaultLightLightnessValues(_ target: Target) {
        target.lightnessTargets[INDEX_MIN] = MIN_LIGHT_LUMA
        target.lightnessTargets[INDEX_TARGET] = TARGET_LIGHT_LUMA
    }
    
    private static func setDefaultVibrantSaturationValues(_ target: Target) {
        target.saturationTargets[INDEX_MIN] = MIN_VIBRANT_SATURATION
        target.saturationTargets[INDEX_TARGET] = TARGET_VIBRANT_SATURATION
    }
    
    private static func setDefaultMutedSaturationValues(_ target: Target) {
        target.saturationTargets[INDEX_TARGET] = TARGET_MUTED_SATURATION
        target.saturationTargets[INDEX_MAX] = MAX_MUTED_SATURATION
    }
}

extension Target {
    
    /**
     * Builder class for generating custom `Target` instances.
     */
    public final class Builder {
        
        private let target: Target
        
        /**
         * Create a new `Target` builder from scratch.
         */
        public required init() {
            self.target = Target()
        }
        
        /**
         * Create a new builder based on an existing `Target`.
         */
        public required init(target: Target) {
            self.target = Target(from: target)
        }
        
        /**
         * Set the minimum saturation value for this target.
         *
         * - Parameter saturation: FloatRange(from = 0, to = 1)
         */
        public func setMinimum(saturation: Float) -> Builder {
            target.saturationTargets[INDEX_MIN] = saturation
            return self
        }
        
        /**
         * Set the target/ideal saturation value for this target.
         *
         * - Parameter saturation: @FloatRange(from = 0, to = 1)
         */
        public func setTarget(saturation: Float) -> Builder {
            target.saturationTargets[INDEX_TARGET] = saturation
            return self
        }
        
        /**
         * Set the maximum saturation value for this target.
         *
         * - Parameter saturation: @FloatRange(from = 0, to = 1)
         */
        public func setMaximum(saturation: Float) -> Builder {
            target.saturationTargets[INDEX_MAX] = saturation
            return self
        }
        
        /**
         * Set the minimum lightness value for this target.
         *
         * - Parameter lightness: @FloatRange(from = 0, to = 1)
         */
        public func setMinimum(lightness: Float) -> Builder {
            target.lightnessTargets[INDEX_MIN] = lightness
            return self
        }
        
        /**
         * Set the target/ideal lightness value for this target.
         *
         * - Parameter lightness: @FloatRange(from = 0, to = 1)
         */
        public func setTarget(lightness: Float) ->  Builder{
            target.lightnessTargets[INDEX_TARGET] = lightness
            return self
        }
        
        /**
         * Set the maximum lightness value for this target.
         *
         * - Parameter lightness: @FloatRange(from = 0, to = 1)
         */
        public func setMaximum(lightness: Float) -> Builder {
            target.lightnessTargets[INDEX_MAX] = lightness
            return self
        }
        
        /**
         * Set the weight of importance that this target will place on saturation values.
         *
         * <p>The larger the weight, relative to the other weights, the more important that a color
         * being close to the target value has on selection.</p>
         *
         * <p>A weight of 0 means that it has no weight, and thus has no
         * bearing on the selection.</p>
         *
         * - see `setTarget(saturation: Float)`
         *
         * - Parameter weight: @FloatRange(from = 0)
         */
        public func setSaturation(weight: Float) -> Builder{
            target.weights[INDEX_WEIGHT_SAT] = weight
            return self
        }
        
        /**
         * Set the weight of importance that this target will place on lightness values.
         *
         * <p>The larger the weight, relative to the other weights, the more important that a color
         * being close to the target value has on selection.</p>
         *
         * <p>A weight of 0 means that it has no weight, and thus has no
         * bearing on the selection.</p>
         *
         * - see `setTarget(lightness: Float)`
         *
         * - Parameter weight: @FloatRange(from = 0)
         */
        public func setLightness(weight: Float) -> Builder {
            target.weights[INDEX_WEIGHT_LUMA] = weight
            return self
        }
        
        /**
         * Set the weight of importance that this target will place on a color's population within
         * the image.
         *
         * <p>The larger the weight, relative to the other weights, the more important that a
         * color's population being close to the most populous has on selection.</p>
         *
         * <p>A weight of 0 means that it has no weight, and thus has no
         * bearing on the selection.</p>
         *
         * - Parameter weight: @FloatRange(from = 0)
         */
        public func setPopulation(weight: Float) -> Builder {
            target.weights[INDEX_WEIGHT_POP] = weight
            return self
        }
        
        /**
         * Set whether any color selected for this target is exclusive to this target only.
         * Defaults to true.
         *
         * - Parameter exclusive: true if any the color is exclusive to this target, or false is the
         *                      color can be selected for other targets.
         */
        public func setExclusive(_ exclusive: Bool) -> Builder {
            target.isExclusive = exclusive
            return self
        }
        
        /**
         * Builds and returns the resulting `Target`.
         */
        public func build() -> Target {
            return target
        }
    }
}

extension Target: Equatable {
    
    public static func ==(lhs: Target, rhs: Target) -> Bool {
        let lh = unsafeBitCast(lhs, to: UnsafePointer<Target>.self)
        let rh = unsafeBitCast(rhs, to: UnsafePointer<Target>.self)
        return lh == rh
    }
}

extension Target: Hashable {
    
    public var hashValue: Int {
        let ptr = unsafeBitCast(self, to: UnsafePointer<Target>.self)
        let hashValue = ptr.hashValue
        return hashValue
    }
}
