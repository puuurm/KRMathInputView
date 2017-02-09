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
    var candidates: [Character] { get }
}

fileprivate extension ByteNode {
    var indexesArray: [Int] {
        let count = indexes.byteCount / MemoryLayout<Int>.stride
        let buffer = indexes.bytes.withMemoryRebound(to: Int.self, capacity: count) {
            UnsafeBufferPointer(start: $0, count: count)
        }
        return Array(buffer)
    }
    
    var candidatesArray: [Character] {
        let count = candidates.byteCount / MemoryLayout<Character>.stride
        let buffer = candidates.bytes.withMemoryRebound(to: Character.self, capacity: count) {
            UnsafeBufferPointer(start: $0, count: count)
        }
        
        return Array(buffer)
    }
}

public struct InkNode: TerminalNodeType {
    public let indexes: [Int]
    public let candidates: [Character]
    
    public init(byteNode: ByteNode) {
        (indexes, candidates) = (byteNode.indexesArray, byteNode.candidatesArray)
    }
    
    public init(indexes: [Int], candidates: [Character]) {
        (self.indexes, self.candidates) = (indexes, candidates)
    }
}

public struct CharacterNode: TerminalNodeType {
    public let indexes: [Int]
    public let candidates: [Character]
    
    public init(byteNode: ByteNode) {
        (indexes, candidates) = (byteNode.indexesArray, byteNode.candidatesArray)
    }
    
    public init(indexes: [Int], candidates: [Character]) {
        (self.indexes, self.candidates) = (indexes, candidates)
    }
}
