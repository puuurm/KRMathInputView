//
//  Node.swift
//  TestScript
//
//  Created by Joshua Park on 06/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

@objc public class Node: NSObject {
    @objc public let ink: [InkType]
    @objc public let frame: CGRect
    @objc public let candidates: [String]
    
    @objc init(ink: [InkType], frame: CGRect, candidates: [String]) {
        self.ink = ink
        self.frame = frame
        self.candidates = candidates
    }
}

@objc open class ObjCNode: NSObject {
    @objc open var frame: CGRect
    @objc open var candidates: [String]
    
    @objc public init(frame: CGRect, candidates: [String]) {
        self.frame = frame
        self.candidates = candidates
    }
    
    @objc public convenience init?(node: Node?) {
        guard let node = node else { return nil }
        self.init(frame: node.frame, candidates: node.candidates)
    }
}
