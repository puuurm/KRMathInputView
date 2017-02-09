//
//  InkParser.swift
//  Pods
//
//  Created by Joshua Park on 09/02/2017.
//
//

import Foundation

@objc public protocol MathInkParserDelegate: NSObjectProtocol {
    func parser(_ parser: MathInkParser, didParseTreeToLaTeX string: NSString, tree: NSArray)
    func parser(_ parser: MathInkParser, didFailWith error: NSError)
}

@objc public protocol MathInkParser {
    weak var delegate: MathInkParserDelegate? { get set }
    
    func addInk(_ strokes: Any)
    func parse()
}

