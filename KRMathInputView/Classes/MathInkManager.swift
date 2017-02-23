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

public protocol MathInkManagerDataSource: class {
    var selectionPadding: CGFloat { get }
    var lineWidth: CGFloat { get }
}

open class MathInkManager: NSObject, MathInkParserDelegate {
    
    public weak var delegate: MathInkManagerDelegate?
    public weak var dataSource: MathInkManagerDataSource?
    
    public private(set) var buffer: UIBezierPath?
    
    public var ink: [InkType] {
        return Array(inkCache.dropLast(inkCache.count - inkIndex))
    }
    
    public var canUndo: Bool { return inkIndex > 0  }
    public var canRedo: Bool { return inkIndex < inkCache.count }
    
    private var inkIndex = 0
    private var inkCache = [InkType]()
    
    private var padding: CGFloat {
        return dataSource!.lineWidth + dataSource!.selectionPadding
    }
    
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
    
    private func getInk(for node: TerminalNodeType) -> [InkType]  {
        var arrInk = [InkType]()
        for i in node.indexes { arrInk.append(ink[i]) }
        
        return arrInk
    }
    
    private func padded(rect: CGRect) -> CGRect {
        return CGRect(x: rect.origin.x - padding,
                      y: rect.origin.y - padding,
                      width: rect.size.width + padding * 2.0,
                      height: rect.size.height + padding * 2.0
        )
    }
    
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
            buffer!.lineWidth = dataSource!.lineWidth
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
            let minX = min(point.x, bufferPoint.x)
            let maxX = max(point.x, bufferPoint.x)
            let minY = min(point.y, bufferPoint.y)
            let maxY = max(point.y, bufferPoint.y)
            
            return padded(rect: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY))
        }()
    }
    
    internal func undo() -> CGRect? {
        guard canUndo else { return nil }
        inkIndex -= 1
        delegate?.manager(self, didUpdateHistory: (canUndo, canRedo))
        process()
        
        return padded(rect: inkCache[inkIndex].frame)
    }
    
    internal func redo() -> CGRect? {
        guard canRedo else { return nil }
        inkIndex += 1
        delegate?.manager(self, didUpdateHistory: (canUndo, canRedo))
        process()
        
        return padded(rect: inkCache[inkIndex - 1].frame)
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
    
    // MARK: - Node
    
    internal func selectNode(at point: CGPoint?) -> Node? {
        guard let point = point else {
            indexOfSelectedNode = nil
            return nil
        }
        
        var arrNodeIndexes = [Int]()
        var nodeInks = [[InkType]]()
        var nodeFrames = [CGRect]()
        
        for (nodeIndex, node) in nodes.enumerated() {
            let ink = getInk(for: node)
            let frame = padded(rect: ink.reduce(ink.first!.frame) { $0.1.frame.union($0.0) })
            
            nodeInks.append(ink)
            nodeFrames.append(frame)

            guard frame.contains(point) else { continue }
            
            arrNodeIndexes.append(nodeIndex)
        }
        
        switch arrNodeIndexes.count {
        case 0: indexOfSelectedNode = nil
        case 1: indexOfSelectedNode = arrNodeIndexes[0]
        default:
            if indexOfSelectedNode == nil {
                indexOfSelectedNode = arrNodeIndexes[0]
            } else {
                if let i = arrNodeIndexes.index(of: indexOfSelectedNode!), i + 1 < arrNodeIndexes.count {
                    indexOfSelectedNode = arrNodeIndexes[i + 1]
                } else {
                    indexOfSelectedNode = arrNodeIndexes[0]
                }
            }
        }
        
        guard let index = indexOfSelectedNode else { return nil }
        
        return Node(ink: nodeInks[index], frame: nodeFrames[index], candidates: nodes[index].candidates)
    }
    
    internal func removeSelectedNode() -> Node? {
        guard indexOfSelectedNode != nil else { return nil }
        
        let node = nodes[indexOfSelectedNode!]
        let ink = getInk(for: node)
        let frame = ink.reduce(ink.first!.frame) { $0.1.frame.union($0.0) }

        for index in node.indexes.sorted(by: >) {
            inkCache.remove(at: index)
        }
        
        inkIndex -= node.indexes.count
        delegate?.manager(self, didUpdateHistory: (canUndo, canRedo))
        
        indexOfSelectedNode = nil
        
        process()
        
        return Node(ink: ink, frame: padded(rect: frame), candidates: node.candidates)
    }
    
    internal func replaceSelectedNode(with character: Character) -> (Node, Node)? {
        guard indexOfSelectedNode != nil else { return nil }

        let node = nodes[indexOfSelectedNode!]
        let arrInk = getInk(for: node)
        let frame = arrInk.reduce(arrInk.first!.frame) { $0.1.frame.union($0.0) }
        
        for index in node.indexes.sorted(by: >) {
            inkCache.remove(at: index)
        }
        
        inkIndex -= node.indexes.count
        delegate?.manager(self, didUpdateHistory: (canUndo, canRedo))

        let charInk = CharacterInk(character: character, frame: frame)
        inkCache.insert(charInk, at: inkIndex)
        inkIndex += 1
        
        indexOfSelectedNode = nil
        
        process()
        
        return (Node(ink: arrInk, frame: padded(rect: frame), candidates: node.candidates),
                Node(ink: [charInk], frame: padded(rect: frame), candidates: [String(character)]))
    }
    
    // MARK: - MathInkParser delegate

    open func parser(_ parser: MathInkParser, didParseTreeToLaTeX string: NSString, leafNodes: NSArray) {
        guard var leafNodes = leafNodes as? [TerminalNodeType] else {
            // TODO: Define error
//            delegate?.manager(self, didFailToParseWith: <#T##NSError#>)
            return
        }
        
        // Get undefined stroke indexes
        var allIndexes: [Int?] = Array(0 ..< ink.count)
        for node in leafNodes {
            for index in node.indexes {
                allIndexes[index] = nil
            }
        }
        let undefinedIndexes = allIndexes.flatMap { $0 }
        
        if !undefinedIndexes.isEmpty {
            let sqrtThresh: CGFloat = 22.0
            for index in undefinedIndexes {
                let stroke = ink[index]
                leafNodes.append(
                    InkNode(indexes: [index],
                            candidates: stroke.frame.height < sqrtThresh ? ["-", "√"] : ["√", "-"])
                )
            }
        }
        
        nodes = leafNodes
        delegate?.manager(self, didParseTreeToLaTex: String(string))
    }
    
    open func parser(_ parser: MathInkParser, didRemoveStrokeAt index: Int) {
        // TODO: Implement
    }
    
    open func parser(_ parser: MathInkParser, didFailWith error: NSError) {
        delegate?.manager(self, didFailToParseWith: error)
    }
    
}
