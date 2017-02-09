//
//  Ink.swift
//  TestScript
//
//  Created by Joshua Park on 08/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

public protocol InkType {
    var frame: CGRect { get }
    var objcType: Any { get }
}

public struct StrokeInk: InkType {

    public let path: UIBezierPath
    public var frame: CGRect { return path.bounds }
    
    public var objcType: Any {
        var arr = NSMutableArray()
        let points = withUnsafeMutablePointer(to: &arr) { UnsafeMutablePointer<NSMutableArray>($0) }
        
        path.cgPath.apply(info: points) { (info, element) in
            let bezierPoints = info?.assumingMemoryBound(to: NSMutableArray.self).pointee
            let points = element.pointee.points
            let type = element.pointee.type
            switch type {
            case .moveToPoint:
                bezierPoints?.add(NSValue(cgPoint: points.pointee))
                break
            case .addLineToPoint:
                bezierPoints?.add(NSValue(cgPoint: points.pointee))
                break
            case .addQuadCurveToPoint:
                bezierPoints?.add(NSValue(cgPoint: points.pointee))
                bezierPoints?.add(NSValue(cgPoint: points.successor().pointee))
                break
            case .addCurveToPoint:
                bezierPoints?.add(NSValue(cgPoint: points.pointee))
                bezierPoints?.add(NSValue(cgPoint: points.successor().pointee))
                bezierPoints?.add(NSValue(cgPoint: points.successor().pointee))
                break
            default:
                break
            }
        }
        return NSArray(array: points.pointee)
    }
    
    public init(path: UIBezierPath) {
        self.path = path
    }
}

public struct CharacterInk: InkType {
    public let character: Character
    public var frame: CGRect
    
    public var objcType: Any {
        return character
    }
    
    public init(character: Character, frame: CGRect) {
        self.character = character
        self.frame = frame
    }
}
