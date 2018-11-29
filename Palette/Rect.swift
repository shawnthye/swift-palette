//
//  Rect.swift
//  Palette
//
//  Created by Shawn Thye on 29/11/2018.
//  Copyright © 2018 Shawn Thye. All rights reserved.
//

extension Rect {
    
    public var left: Int {
        get { return Int(origin.x) }
        set { origin.x = CGFloat(newValue) }
    }
    
    public var top: Int {
        get { return Int(origin.y) }
        set { origin.y = CGFloat(newValue) }
    }
    
    public var right: Int {
        get { return left + Int(width) }
        set { size.width = CGFloat(newValue - left) }
    }
    
    public var bottom: Int {
        get { return top + Int(height) }
        set { size.height = CGFloat(newValue - top) }
    }
    
    public init(left: Int, top: Int, right: Int, bottom: Int) {
        self.init()
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }
}
