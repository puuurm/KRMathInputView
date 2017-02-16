//
//  MathInkManager.swift
//  TestScript
//
//  Created by Joshua Park on 06/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

public protocol MathInkManagerDelegate: class {
    func manager(_ manager: MathInkManager, didParseTreeToLaTex string: String)
    func manager(_ manager: MathInkManager, didFailToParseWith error: NSError)
    func manager(_ manager: MathInkManager, didUpdateHistory state: (undo: Bool, redo: Bool))
}

open class MathInkManager: NSObject, MathInkParserDelegate {
    
    public weak var delegate: MathInkManagerDelegate?
    
    public var lineWidth: CGFloat = 3.0
    
    public private(set) var buffer: UIBezierPath?
    
    public var ink: [InkType] {
        return Array(inkCache.dropLast(inkCache.count - inkIndex))
    }
    
    public var canUndo: Bool { return inkIndex > 0  }
    public var canRedo: Bool { return inkIndex < inkCache.count }
    
    private var inkIndex = 0
    private var inkCache = [InkType]()
    
    open var parser: MathInkParser? {
        didSet { parser?.delegate = self }
    }
    
    public private(set) var nodes = [TerminalNodeType]()
    public private(set) var indexOfSelectedNode: Int?
    
    // MARK: - Test
    
    public func test(with ink: [InkType], nodes: [TerminalNodeType]) {
        self.inkCache = ink
        self.nodes = nodes
    }
    
    public func testSelectNode(at point: CGPoint) -> Node? {
        return selectNode(at: point)
    }
    
    // MARK: - Ink
    
    internal func addInkFromBuffer() {
        if inkIndex < inkCache.count { inkCache.removeSubrange(inkIndex ..< inkCache.count) }
        
        inkCache.append(StrokeInk(path: buffer!))
        inkIndex += 1
    }
    
    @discardableResult
    internal func inputStream(at point: CGPoint, previousPoint: CGPoint, isLast: Bool = false) -> CGRect {
        func midPoint() -> CGPoint {
            return CGPoint(x: (point.x + previousPoint.x) * 0.5,
                           y: (point.y + previousPoint.y) * 0.5)
        }
        
        if buffer == nil {
            buffer = UIBezierPath()
            buffer!.lineWidth = lineWidth
            buffer!.lineCapStyle = .round
            buffer!.move(to: previousPoint)
        }
        
        let bufferPoint = buffer!.currentPoint
        
        if !isLast {
            buffer!.addQuadCurve(to: midPoint(), controlPoint: previousPoint)
        } else {
            buffer!.addQuadCurve(to: point, controlPoint: previousPoint)
            addInkFromBuffer()
            buffer = nil
        }
        
        delegate?.manager(self, didUpdateHistory: (canUndo, canRedo))
        
        return { () -> CGRect in
            let minX = min(point.x, bufferPoint.x) - lineWidth * 2.0
            let maxX = max(point.x, bufferPoint.x) + lineWidth * 4.0
            let minY = min(point.y, bufferPoint.y) - lineWidth * 2.0
            let maxY = max(point.y, bufferPoint.y) + lineWidth * 4.0
            
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }()
    }
    
    internal func undo() -> CGRect? {
        guard canUndo else { return nil }
        inkIndex -= 1
        delegate?.manager(self, didUpdateHistory: (canUndo, canRedo))
        return { () -> CGRect in
            var frame = inkCache[inkIndex].frame
            frame.origin.x -= lineWidth * 2.0
            frame.origin.y -= lineWidth * 2.0
            frame.size.width += lineWidth * 4.0
            frame.size.height += lineWidth * 4.0
            return frame
        }()
    }
    
    internal func redo() -> CGRect? {
        guard canRedo else { return nil }
        inkIndex += 1
        delegate?.manager(self, didUpdateHistory: (canUndo, canRedo))
        return { () -> CGRect in
            var frame = inkCache[inkIndex - 1].frame
            frame.origin.x -= lineWidth * 2.0
            frame.origin.y -= lineWidth * 2.0
            frame.size.width += lineWidth * 4.0
            frame.size.height += lineWidth * 4.0
            return frame
            }()
    }
    
    internal func process() {
        guard let parser = parser else {
            // TODO: Define error
            delegate?.manager(self, didFailToParseWith: NSError(domain: "tempdomain", code: 0))
            return
        }
        
        parser.addInk(NSArray(array: ink.map { $0.objcType }))
        parser.parse()
    }
    
    internal func selectNode(at point: CGPoint) -> Node? {
        var candidateIndexes = [Int]()
        var nodeStrokes = [[InkType]]()
        var nodeFrames = [CGRect]()
        
        for (nodeIndex, node) in nodes.enumerated() {
            var strokes = [InkType]()
            for i in node.indexes { strokes.append(inkCache[i]) }
            let bounds = strokes.reduce(strokes.first!.frame) { $0.1.frame.union($0.0) }
            
            nodeStrokes.append(strokes)
            nodeFrames.append(bounds)

            guard bounds.contains(point) else { continue }
            
            candidateIndexes.append(nodeIndex)
        }
        
        switch candidateIndexes.count {
        case 0: indexOfSelectedNode = nil
        case 1: indexOfSelectedNode = candidateIndexes[0]
        default:
            if indexOfSelectedNode == nil {
                indexOfSelectedNode = candidateIndexes[0]
            } else {
                if let i = candidateIndexes.index(of: indexOfSelectedNode!), i + 1 < candidateIndexes.count {
                    indexOfSelectedNode = candidateIndexes[i + 1]
                } else {
                    indexOfSelectedNode = candidateIndexes[0]
                }
            }
        }
        
        guard let index = indexOfSelectedNode else { return nil }
        
        return Node(ink: nodeStrokes[index], frame: nodeFrames[index])
    }
    
    // MARK: - MathInkParser delegate

    open func parser(_ parser: MathInkParser, didParseTreeToLaTeX string: NSString, leafNodes: NSArray) {
        guard let leafNodes = leafNodes as? [TerminalNodeType] else {
            // TODO: Define error
//            delegate?.manager(self, didFailToParseWith: <#T##NSError#>)
            return
        }
        
        // FIXME: ** TEST CODE **
        print(leafNodes);
        // **
        
        // TODO: Set leaf nodes and undefined rule nodes
//        nodes = leafNodes
        delegate?.manager(self, didParseTreeToLaTex: String(string))
    }
    
    open func parser(_ parser: MathInkParser, didFailWith error: NSError) {
        delegate?.manager(self, didFailToParseWith: error)
    }
    
}
