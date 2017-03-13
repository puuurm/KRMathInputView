//
//  Ink.swift
//  TestScript
//
//  Created by Joshua Park on 08/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

public protocol InkType {
    var path: UIBezierPath { get }
    var frame: CGRect { get }
}

public protocol CharacterInkType: InkType {
    var character: Character { get }
}

public protocol RemovingInkType: InkType {
    var indexes: Set<Int> { get }
}

public protocol ObjCConvertible {
    var objCType: NSObject { get }
}

public typealias ObjCInk = InkType & ObjCConvertible

public struct StrokeInk: ObjCInk {

    public let path: UIBezierPath
    public var frame: CGRect { return path.bounds }
    
    public var objCType: NSObject {
        return NSArray(array: path.points.map { NSValue(cgPoint: $0) })
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

public struct CharacterInk: ObjCInk, CharacterInkType, RemovingInkType {
    
    public let character: Character
    public let path: UIBezierPath
    public var frame: CGRect { return path.bounds }
    
    public var objCType: NSObject {
        return CharacterInkValue(character: character, frame: frame)
    }
    
    public let indexes: Set<Int>
    
}

internal struct RemovedInk: RemovingInkType {
    
    internal let indexes: Set<Int>
    internal let path: UIBezierPath
    var frame: CGRect { return path.bounds }
    
}

