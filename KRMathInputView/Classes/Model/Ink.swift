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
}

public protocol ObjCConvertible {
    var objCType: NSObjectProtocol { get }
}

public typealias Ink = InkType & ObjCConvertible

public struct StrokeInk: Ink {

    public let path: UIBezierPath
    public var frame: CGRect { return path.bounds }
    
    public var objCType: NSObjectProtocol {
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

@objc public class CharacterInkValue: NSObject {
    
    public let character: NSString
    public let frame: NSValue
    
    init(character: Character, frame: CGRect) {
        self.character = NSString(string: String(character))
        self.frame = NSValue(cgRect: frame)
    }
    
    init(character: NSString, frame: NSValue) {
        self.character = character
        self.frame = frame
    }
    
}

public struct CharacterInk: Ink {
    
    public let character: Character
    public var frame: CGRect
    
    public var objCType: NSObjectProtocol {
        return CharacterInkValue(character: character, frame: frame)
    }
    
    public init(character: Character, frame: CGRect) {
        self.character = character
        self.frame = frame
    }
    
}

internal struct RemovedInk: InkType {
    var indexes: Set<Int>
    var frame: CGRect
}
