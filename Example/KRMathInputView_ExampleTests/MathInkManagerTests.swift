//
//  MathInkManagerTests.swift
//  TestScript
//
//  Created by Joshua Park on 06/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import XCTest
import KRMathInputView

class TestParser: MathInkParser {
    var delegate: MathInkParserDelegate?
    
    func addInk(_ strokes: NSArray) {}
    func parse() {}
}

class TestRenderer: MathInkRendering {
    var nodePadding: CGFloat = 8.0
    
    func manager(_ manager: MathInkManager, didExtractLaTeX string: String) {}
    func manager(_ manager: MathInkManager, didFailToExtractWith error: NSError) {}
    func manager(_ manager: MathInkManager, didUpdateHistory state: (undo: Bool, redo: Bool)) {}
    func manager(_ manager: MathInkManager, didLoad ink: [InkType]) {}
}

class MathInkManagerTests: XCTestCase {
    let manager = MathInkManager()
    let parser = TestParser()
    let renderer = TestRenderer()
    
    override func setUp() {
        super.setUp()

        manager.renderer = renderer
        parser.delegate = manager
        
        let path1 = UIBezierPath()
        path1.move(to: CGPoint.zero)
        path1.addLine(to: CGPoint(x: 100.0, y: 100.0))
        
        let path2 = UIBezierPath()
        path2.move(to: CGPoint(x: 25.0, y: 25.0))
        path2.addLine(to: CGPoint(x: 125.0, y: 125.0))
        
        let path3 = UIBezierPath()
        path3.move(to: CGPoint(x: 50.0, y: 50.0))
        path3.addLine(to: CGPoint(x: 150.0, y: 150.0))
        
        let path4 = UIBezierPath()
        path4.move(to: CGPoint(x: 0.0, y: 200.0))
        path4.addLine(to: CGPoint(x: 100.0, y: 300.0))
        
        let ink = [path1, path2, path3, path4].map { StrokeInk(path: $0) }
        manager.load(ink: ink)
        
        var nodes = [CharacterNode]()
        
        for i in 0 ..< ink.count {
            nodes.append(CharacterNode(indexes: [i], candidates: ["1"]))
        }
        
        parser.delegate?.parser(parser, didExtractLaTeX: "", leafNodes: NSArray(array: nodes))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInkManagerLoadInk() {
        
    }
    
    func testInkManagerSelectNodeAtPoint() {
        let testPoints = [
            CGPoint(x: 99.0, y: 0.0),
            CGPoint(x: 124.0, y: 25.0),
            CGPoint(x: 149.0, y: 50.0),
            CGPoint(x: 0.0, y: 200.0),
            CGPoint(x: 500.0, y: 500.0)
        ]
        
        for i in 0 ..< testPoints.count {
            let selectedNode = manager.selectNode(at: testPoints[i])
        
            switch i {
            case 4:
                XCTAssertNil(selectedNode, "No nodes should be selected for \(testPoints[i]).")
                XCTAssertNil(manager.indexOfSelectedNode,
                             "`indexOfSelectedNode` should be `nil`. Index of selected node: \(manager.indexOfSelectedNode!)")
            default:
                XCTAssertNotNil(selectedNode, "A node should be selected for \(testPoints[i]).")
                XCTAssertNotNil(manager.indexOfSelectedNode, "`indexOfSelectedNode` should not be `nil`.")
            }
            
            if let index = manager.indexOfSelectedNode {
                print(":: SELECTED NODE INDEX: \(index)")
            } else {
                print(":: NO SELECTED NODE")
            }
            
        }
    }
    
    func testInkManagerSelectNodeAtPointRotation() {
        let testPoint = CGPoint(x: 50.0, y: 50.0)
        
        for i in 0 ..< 10 {
            let selectedNode = manager.selectNode(at: testPoint)
            XCTAssertNotNil(selectedNode, "A node should be selected for \(testPoint).")
            XCTAssertNotNil(manager.indexOfSelectedNode, "`indexOfSelectedNode` should not be `nil`.")
            XCTAssertEqual(i % 3, manager.indexOfSelectedNode!, "A wrong index is selected.")
            
            print(":: SELECTED NODE INDEX: \(manager.indexOfSelectedNode!)")
        }
        
    }
}
