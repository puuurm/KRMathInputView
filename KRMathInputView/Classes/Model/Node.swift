//
//  Node.swift
//  TestScript
//
//  Created by Joshua Park on 06/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

@objc public class Node: NSObject {
    public let ink: [InkType]
    public let frame: CGRect
    public let candidates: [String]
    
    init(ink: [InkType], frame: CGRect, candidates: [String]) {
        self.ink = ink
        self.frame = frame
        self.candidates = candidates
    }
}

@objc open class ObjCNode: NSObject {
    open var frame: CGRect
    open var candidates: [String]
    
    public init(frame: CGRect, candidates: [String]) {
        self.frame = frame
        self.candidates = candidates
    }
    
    public convenience init?(node: Node?) {
        guard let node = node else { return nil }
        self.init(frame: node.frame, candidates: node.candidates)
    }
}
