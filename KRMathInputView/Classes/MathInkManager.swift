//
//  MathInkManager.swift
//  TestScript
//
//  Created by Joshua Park on 06/02/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

public protocol MathInkRendering: class {
    var nodePadding: CGFloat { get }
    
    func manager(_ manager: MathInkManager, didExtractLaTeX string: String)
    func manager(_ manager: MathInkManager, didFailToExtractWith error: NSError)
    func manager(_ manager: MathInkManager, didUpdateHistory state: (undo: Bool, redo: Bool))
}

open class MathInkManager: NSObject, MathInkParserDelegate {
    
    public weak var renderer: MathInkRendering?
    
    public private(set) var buffer: UIBezierPath?
    
    public var ink: [Ink] {
        var ink = [Ink]()
        var arrIndexSet = [Set<Int>]()
        
        for inkInstance in Array(inkCache.dropLast(inkCache.count - inkIndex)) {
            if let inkInstance = inkInstance as? Ink {
                ink.append(inkInstance)
                
                if let rInk = inkInstance as? CharacterInk {
                    arrIndexSet.append(rInk.replacedIndexes)
                }
            } else {
                arrIndexSet.append((inkInstance as! RemovedInk).indexes)
            }
        }
        
        for indexSet in arrIndexSet {
            for index in indexSet.sorted(by: >) {
                ink.remove(at: index)
            }
        }

        return ink
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
    
    // MARK: - Ink
    
    private func getInk(for indexes: [Int]) -> (arrInk: [InkType], frame: CGRect)  {
        var arrInk = [InkType]()
        for i in indexes { arrInk.append(ink[i]) }
        
        return (arrInk, arrInk.reduce(arrInk.first!.frame) { $0.1.frame.union($0.0) })
    }
    
    private func getPath(from inkArray: [InkType]) -> UIBezierPath {
        return inkArray.reduce(UIBezierPath()) { (path, ink) -> UIBezierPath in
            path.append(ink.path)
            return path
        }
    }
    
    private func padded(rect: CGRect) -> CGRect {
        return CGRect(x: rect.origin.x - renderer!.nodePadding,
                      y: rect.origin.y - renderer!.nodePadding,
                      width: rect.size.width + renderer!.nodePadding * 2.0,
                      height: rect.size.height + renderer!.nodePadding * 2.0
        )
    }
    
    public func add(ink: InkType) {
        if inkIndex < inkCache.count { inkCache.removeSubrange(inkIndex ..< inkCache.count) }
        
        inkCache.append(ink)
        inkIndex += 1
    }
    
    @discardableResult
    public func inputStream(at point: CGPoint, previousPoint: CGPoint, isLast: Bool = false) -> CGRect {
        func midPoint() -> CGPoint {
            return CGPoint(x: (point.x + previousPoint.x) * 0.5,
                           y: (point.y + previousPoint.y) * 0.5)
        }
        
        if buffer == nil {
            buffer = UIBezierPath()
            buffer!.lineCapStyle = .round
            buffer!.move(to: previousPoint)
        }
        
        let bufferPoint = buffer!.currentPoint
        
        if !isLast {
            buffer!.addQuadCurve(to: midPoint(), controlPoint: previousPoint)
        } else {
            buffer!.addQuadCurve(to: point, controlPoint: previousPoint)
            add(ink: StrokeInk(path: buffer!))
            buffer = nil
        }
        
        renderer?.manager(self, didUpdateHistory: (canUndo, canRedo))
        
        return { () -> CGRect in
            let minX = min(point.x, bufferPoint.x)
            let maxX = max(point.x, bufferPoint.x)
            let minY = min(point.y, bufferPoint.y)
            let maxY = max(point.y, bufferPoint.y)
            
            return padded(rect: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY))
        }()
    }
    
    public func undo() -> CGRect? {
        guard canUndo else { return nil }
        inkIndex -= 1
        renderer?.manager(self, didUpdateHistory: (canUndo, canRedo))
        process()
        
        return padded(rect: inkCache[inkIndex].frame)
    }
    
    public func redo() -> CGRect? {
        guard canRedo else { return nil }
        inkIndex += 1
        renderer?.manager(self, didUpdateHistory: (canUndo, canRedo))
        process()
        
        return padded(rect: inkCache[inkIndex - 1].frame)
    }
    
    public func process() {
        guard let parser = parser else {
            // TODO: Define error
            renderer?.manager(self, didFailToExtractWith: NSError(domain: "tempdomain", code: 0))
            return
        }
        
        parser.addInk(NSArray(array: ink.map { $0.objCType }))
        parser.parse()
    }
    
    // MARK: - Node
    
    public func selectNode(at point: CGPoint?) -> Node? {
        guard let point = point else {
            indexOfSelectedNode = nil
            return nil
        }
        
        var arrNodeIndexes = [Int]()
        var nodeInks = [[InkType]]()
        var nodeFrames = [CGRect]()
        
        for (nodeIndex, node) in nodes.enumerated() {
            let (arrInk, frame) = getInk(for: node.indexes)
            
            nodeInks.append(arrInk)
            nodeFrames.append(padded(rect: frame))

            guard nodeFrames.last!.contains(point) else { continue }
            
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
    
    public func removeSelectedNode() -> Node? {
        guard indexOfSelectedNode != nil else { return nil }
        
        let node = nodes[indexOfSelectedNode!]
        let (arrInk, frame) = getInk(for: node.indexes)
        
        add(ink: RemovedInk(indexes: Set(node.indexes), path: getPath(from: ink)))
        
        renderer?.manager(self, didUpdateHistory: (canUndo, canRedo))
        
        indexOfSelectedNode = nil
        
        process()
        
        return Node(ink: arrInk, frame: padded(rect: frame), candidates: node.candidates)
    }
    
    public func replaceSelectedNode(with character: Character) -> (Node, Node)? {
        guard indexOfSelectedNode != nil else { return nil }

        let node = nodes[indexOfSelectedNode!]
        let (arrInk, frame) = getInk(for: node.indexes)
        
        let charInk = CharacterInk(character: character,
                                   path: getPath(from: arrInk),
                                   replacedIndexes: Set(node.indexes))
        add(ink: charInk)

        indexOfSelectedNode = nil
        
        process()
        
        return (Node(ink: arrInk, frame: padded(rect: frame), candidates: node.candidates),
                Node(ink: [charInk], frame: padded(rect: frame), candidates: [String(character)]))
    }
    
    // MARK: - MathInkParser delegate

    open func parser(_ parser: MathInkParser, didExtractLaTeX string: NSString, leafNodes: NSArray) {
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
        renderer?.manager(self, didExtractLaTeX: String(string))
    }
    
    open func parser(_ parser: MathInkParser, didRemoveStrokeAt indexes: [Int]) {
        // TODO: Implement
    }
    
    open func parser(_ parser: MathInkParser, didFailWith error: NSError) {
        renderer?.manager(self, didFailToExtractWith: error)
    }
    
}
