//
//  TerminalNode.swift
//  TestScript
//
//  Created by Joshua Park on 08/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

public protocol TerminalNodeType {
    var indexes: [Int] { get }
    var candidates: [String] { get }
}

@objc public class InkNode: NSObject, TerminalNodeType {
    public let indexes: [Int]
    public let candidates: [String]
    
    override public var description: String {
        return "<InkNode: stroke indexes=\(indexes); candidates=\(candidates)>"
    }
    
    public init(indexes: [Int], candidates: [String]) {
        (self.indexes, self.candidates) = (indexes, candidates)
    }
}

@objc public class CharacterNode: NSObject, TerminalNodeType {
    public let indexes: [Int]
    public let candidates: [String]
    
    override public var description: String {
        return "<CharacterNode: index=\(indexes[0]); character=\(candidates[0])>"
    }
    
    public init(indexes: [Int], candidates: [String]) {
        (self.indexes, self.candidates) = (indexes, candidates)
    }
}
