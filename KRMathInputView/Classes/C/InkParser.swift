//
//  InkParser.swift
//  Pods
//
//  Created by Joshua Park on 09/02/2017.
//
//

import Foundation

public protocol MathInkParserDelegate: class {
    func parser(_ parser: MathInkParser,
                didParseTreeTo latexString: UnsafeMutablePointer<Character>,
                node: UnsafeMutablePointer<NSArray>)
    
    func parser(_ parser: MathInkParser, didFailWith error: NSError)
}

public protocol MathInkParser {
    var delegate: MathInkParserDelegate { get set }
    
    func addInk(_ strokes: Any)
    func parse()
}

