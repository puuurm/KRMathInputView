//
//  InkParser.swift
//  Pods
//
//  Created by Joshua Park on 09/02/2017.
//
//

import Foundation

@objc public protocol MathInkParserDelegate: NSObjectProtocol {
    func parser(_ parser: MathInkParser, didExtractLaTeX string: NSString, leafNodes: NSArray)
    func parser(_ parser: MathInkParser, didFailWith error: NSError)
    func parser(_ parser: MathInkParser, didRemoveStrokeAt indexes: [Int])
}

@objc public protocol MathInkParser {
    weak var delegate: MathInkParserDelegate? { get set }
    
    func addInk(_ strokes: NSArray)
    func parse()
}

