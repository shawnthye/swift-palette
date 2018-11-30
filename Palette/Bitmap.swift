//
//  Bitmap+Palette.swift
//  Palette
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

extension Bitmap {
    
    func resize(_ scaleRatio: Double) -> Bitmap {
        let image = UIImage(cgImage: self)
        let size = image.size.applying(CGAffineTransform(scaleX: CGFloat(scaleRatio), y: CGFloat(scaleRatio)))
        
        //let hasAlpha = false
        //let scale: CGFloat = 1.0
        
        //UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: .zero, size: size))
        
        let context = UIGraphicsGetImageFromCurrentImageContext()
        let scaledBitmap = context?.cgImage
        UIGraphicsEndImageContext()
        
        guard let bitmap = scaledBitmap else {
            return self
        }
        
        return bitmap
    }
    
    private func createARGBBitmapContext() -> CGContext? {
        
        //Get image width, height
        let pixelsWide = self.width
        let pixelsHigh = self.height
        
        // Declare the number of bytes per row. Each pixel in the bitmap in this
        // example is represented by 4 bytes; 8 bits each of red, green, blue, and
        // alpha.
        let bitmapBytesPerRow = Int(pixelsWide) * 4
        
        // Use the generic RGB color space.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Allocate memory for image data. This is the destination in memory
        // where any drawing to the bitmap context will be rendered.
        let bitmapData = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapBytesPerRow * pixelsHigh)
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
        
        // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
        // per component. Regardless of what the source image format is
        // (CMYK, Grayscale, and so on) it will be converted over to the format
        // specified here by CGBitmapContextCreate.
        let context = CGContext(data: bitmapData, width: pixelsWide, height: pixelsHigh, bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        
        return context
    }
    
    /**
     * Returns in pixels[] a copy of the data in the bitmap. Each value is
     * a packed int representing a {@link Color}. The stride parameter allows
     * the caller to allow for gaps in the returned pixels array between
     * rows. For normal packed results, just pass width for the stride value.
     * The returned colors are non-premultiplied ARGB values in the
     * {@link ColorSpace.Named#SRGB sRGB} color space.
     *
     * @param pixels   The array to receive the bitmap's colors
     * @param offset   The first index to write into pixels[]
     * @param stride   The number of entries in pixels[] to skip between
     *                 rows (must be >= bitmap's width). Can be negative.
     * @param x        The x coordinate of the first pixel to read from
     *                 the bitmap
     * @param y        The y coordinate of the first pixel to read from
     *                 the bitmap
     * @param width    The number of pixels to read from each row
     * @param height   The number of rows to read
     *
     * @throws IllegalArgumentException if x, y, width, height exceed the
     *         bounds of the bitmap, or if abs(stride) < width.
     * @throws ArrayIndexOutOfBoundsException if the pixels array is too small
     *         to receive the specified number of pixels.
     * @throws IllegalStateException if the bitmap's config is {@link Config#HARDWARE}
     */
    func getPixels(pixels: inout [ColorInt]) {
        guard let context = self.createARGBBitmapContext() else {
            return
        }
        
        let pixelsWide = self.width
        let pixelsHigh = self.height
        let bytesPerPixel = context.bitsPerPixel / 8
        
        let rect = CGRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh)
        
        //Clear the context
        context.clear(rect)
        
        // Draw the image to the bitmap context. Once we draw, the memory
        // allocated for the context for rendering will then contain the
        // raw image data in the specified color space.
        context.draw(self, in: rect)
        
        // Now we can get a pointer to the image data associated with the bitmap
        // context.
        guard let data = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return
        }
        
        let bytes = UnsafeMutablePointer<UInt8>(data)
        
        for y in 0..<pixelsHigh {
            for x in 0..<pixelsWide {
                let pos = (y * pixelsWide) + x
                let pixel = pos * bytesPerPixel
                pixels[pos] = Color.argb(alpha: Int(bytes[pixel]),
                                           red: Int(bytes[pixel + 1]),
                                           green: Int(bytes[pixel + 2]),
                                           blue: Int(bytes[pixel + 3]))
            }
        }
    }
}
