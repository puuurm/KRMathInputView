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
    func manager(_ manager: MathInkManager, didLoad ink: [InkType]?)
    func manager(_ manager: MathInkManager, didScratchOut frame: CGRect)
}

@objc open class MathInkManager: NSObject, MathInkParserDelegate {
    
    open weak var renderer: MathInkRendering?
    
    open private(set) var buffer: UIBezierPath?
    
    open var ink: [ObjCInk] {
        var ink = [ObjCInk]()
        var arrIndexSet = [Set<Int>]()
        
        for inkInstance in Array(inkCache.dropLast(inkCache.count - inkIndex)) {
            if let inkInstance = inkInstance as? ObjCInk {
                if let cInk = inkInstance as? CharacterInkType {
                    ink.append(CharacterInk(character: cInk.character,
                                            path: cInk.path,
                                            indexes: Set<Int>()))
                } else {
                    ink.append(inkInstance)
                }
            }
            
            if let removingInk = inkInstance as? RemovingInkType {
                arrIndexSet.append(removingInk.indexes)
            }
        }
        
        for indexSet in arrIndexSet {
            for index in indexSet.sorted(by: >) {
                ink.remove(at: index)
            }
        }

        return ink
    }
    
    open var canUndo: Bool { return inkIndex > 0  }
    open var canRedo: Bool { return inkIndex < inkCache.count }
    
    private var inkIndex = 0
    private var inkCache = [InkType]()
    
    open var parser: MathInkParser? {
        didSet { parser?.delegate = self }
    }
    
    open private(set) var nodes = [TerminalNodeType]()
    open private(set) var indexOfSelectedNode: Int?
    
    public var selectedNode: Node? {
        guard indexOfSelectedNode != nil else { return nil }
        
        let node = nodes[indexOfSelectedNode!]
        let (ink, frame) = getInk(for: node.indexes)
        
        return Node(ink: ink,
                    frame: padded(rect: frame),
                    candidates: node.candidates)
    }
    
    // MARK: - Ink
    
    private func getInk(for indexes: [Int]) -> (arrInk: [InkType], frame: CGRect)  {
        var arrInk = [InkType]()
        for i in indexes { arrInk.append(ink[i]) }
        
        return (arrInk, arrInk.reduce(arrInk.first!.frame) { $1.frame.union($0) })
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
    
    open func add(ink: InkType) {
        if inkIndex < inkCache.count { inkCache.removeSubrange(inkIndex ..< inkCache.count) }
        
        inkCache.append(ink)
        inkIndex += 1
        
        process()
    }
    
    open func load(ink: [InkType]?) {
        inkCache = ink ?? [InkType]()
        inkIndex = inkCache.count
        indexOfSelectedNode = nil
        
        if ink != nil { process() }
        
        renderer!.manager(self, didLoad: ink)
    }
    
    @discardableResult
    open func inputStream(at point: CGPoint, previousPoint: CGPoint, isLast: Bool = false) -> CGRect {
        func midPoint() -> CGPoint {
            return CGPoint(x: (point.x + previousPoint.x) * 0.5,
                           y: (point.y + previousPoint.y) * 0.5)
        }
        
        if buffer == nil {
            buffer = UIBezierPath()
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
    
    open func undo() -> CGRect? {
        guard canUndo else { return nil }
        inkIndex -= 1
        renderer?.manager(self, didUpdateHistory: (canUndo, canRedo))
        process()
        
        return padded(rect: inkCache[inkIndex].frame)
    }
    
    open func redo() -> CGRect? {
        guard canRedo else { return nil }
        inkIndex += 1
        renderer?.manager(self, didUpdateHistory: (canUndo, canRedo))
        process()
        
        return padded(rect: inkCache[inkIndex - 1].frame)
    }
    
    open func process() {
        guard let parser = parser else {
            // TODO: Define error
            renderer?.manager(self, didFailToExtractWith: NSError(domain: "tempdomain", code: 0))
            return
        }
        
        parser.addInk(NSArray(array: ink.map { $0.objCType }))
        parser.parse()
    }
    
    // MARK: - Node
    
    @discardableResult
    open func selectNode(at point: CGPoint?) -> Node? {
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
    
    open func removeSelectedNode() -> Node? {
        guard indexOfSelectedNode != nil else { return nil }
        
        let node = nodes[indexOfSelectedNode!]
        let (arrInk, frame) = getInk(for: node.indexes)
        
        add(ink: RemovedInk(indexes: Set(node.indexes), path: getPath(from: ink)))
        
        renderer?.manager(self, didUpdateHistory: (canUndo, canRedo))
        
        indexOfSelectedNode = nil
        
        
        return Node(ink: arrInk, frame: padded(rect: frame), candidates: node.candidates)
    }
    
    open func replaceSelectedNode(with character: String) -> (Node, Node)? {
        guard indexOfSelectedNode != nil else { return nil }

        let node = nodes[indexOfSelectedNode!]
        let (arrInk, frame) = getInk(for: node.indexes)
        
        let charInk = CharacterInk(character: character,
                                   path: getPath(from: arrInk),
                                   indexes: Set(node.indexes))
        add(ink: charInk)

        indexOfSelectedNode = nil
        
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
        let undefinedIndexes = allIndexes.compactMap { $0 }
        
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
    
    open func parser(_ parser: MathInkParser, didScratchOut indexes: [Int]) { }
    
    open func parser(_ parser: MathInkParser, didFailWith error: NSError) {
        nodes.removeAll()
        renderer?.manager(self, didFailToExtractWith: error)
    }
    
}
