//
//  TerminalNode.swift
//  TestScript
//
//  Created by Joshua Park on 08/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

@objc public protocol TerminalNodeType {
    var indexes: [Int] { get }
    var candidates: [String] { get }
}

public class InkNode: NSObject, TerminalNodeType {
    public let indexes: [Int]
    public let candidates: [String]
    
    override public var description: String {
        return "<InkNode: stroke indexes=\(indexes); candidates=\(candidates)>"
    }
    
    @objc public init(indexes: [Int], candidates: [String]) {
        (self.indexes, self.candidates) = (indexes, candidates)
    }
}

public class CharacterNode: NSObject, TerminalNodeType {
    public let indexes: [Int]
    public let candidates: [String]
    
    override public var description: String {
        return "<CharacterNode: index=\(indexes); character=\(candidates)>"
    }
    
    @objc public init(indexes: [Int], candidates: [String]) {
        (self.indexes, self.candidates) = (indexes, candidates)
    }
}
