//
//  Ink.swift
//  TestScript
//
//  Created by Joshua Park on 08/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

@objc public protocol InkType {
    var path: UIBezierPath { get }
    var frame: CGRect { get }
}

@objc public protocol CharacterInkType: InkType {
    var character: String { get }
}

@objc public protocol RemovingInkType: InkType {
    var indexes: Set<Int> { get }
}

@objc public protocol ObjCConvertible {
    var objCType: NSObject { get }
}

public typealias ObjCInk = InkType & ObjCConvertible

@objc public class StrokeInk: NSObject, ObjCInk {

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
    
    init(character: String, frame: CGRect) {
        self.character = NSString(string: character)
        self.frame = NSValue(cgRect: frame)
    }
    
    init(string: NSString, frame: NSValue) {
        self.character = string
        self.frame = frame
    }
    
}

@objc public class CharacterInk: NSObject, ObjCInk, CharacterInkType, RemovingInkType {
    
    public let character: String
    public let path: UIBezierPath
    public var frame: CGRect { return path.bounds }
    
    public var objCType: NSObject {
        return CharacterInkValue(character: character, frame: frame)
    }
    
    public let indexes: Set<Int>
    
    init(character: String, path: UIBezierPath, indexes: Set<Int>) {
        self.character = character
        self.path = path
        self.indexes = indexes
    }
    
}

internal class RemovedInk: NSObject, RemovingInkType {
    
    internal let indexes: Set<Int>
    internal let path: UIBezierPath
    var frame: CGRect { return path.bounds }
 
    init(indexes: Set<Int>, path: UIBezierPath) {
        self.indexes = indexes
        self.path = path
    }
    
}

