//
//  MathInputView.swift
//  TestScript
//
//  Created by Joshua Park on 31/01/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

@objc public protocol MathInputViewDelegate: NSObjectProtocol {
    
    func mathInputView(_ mathInputView: MathInputView, didTap node: ObjCNode?)
    func mathInputView(_ mathInputView: MathInputView, didLongPress node: ObjCNode?)
    func mathInputView(_ mathInputView: MathInputView, didRemove node: ObjCNode)
    func mathInputView(_ mathInputView: MathInputView, didReplace oldNode: ObjCNode, with newNode: ObjCNode)
    
    func mathInputView(_ mathInputView: MathInputView, didParse ink: [Any], latex: String)
    func mathInputView(_ mathInputView: MathInputView, didFailToParse ink: [Any], with error: NSError)
    func mathInputView(_ mathInputView: MathInputView, didChangeModeTo isWritingMode: Bool)
    
}

private typealias ProtocolCollection = MathInkRendering & KeyboardTypeDelegate & KeyboardTypeDataSource

open class MathInputView: UIView, ProtocolCollection {
    
    open weak var delegate: MathInputViewDelegate?
    
    open var isWritingMode: Bool = true {
        willSet {
            tapGestureRecognizer.isEnabled = !newValue
            longPressGestureRecognizer.isEnabled = !newValue
            
            if !isWritingMode && newValue {
                manager.selectNode(at: nil)
                display(node: nil)
                delegate?.mathInputView(self, didTap: nil)
            }
        }
        didSet {
            if oldValue != isWritingMode {
                delegate?.mathInputView(self, didChangeModeTo: isWritingMode)
            }
        }
    }
    
    open var manager = MathInkManager()
    
    @IBOutlet open weak var undoButton: UIButton?
    @IBOutlet open weak var redoButton: UIButton?
    
    public var lineWidth: CGFloat = 3.0
    public var selectionPadding: CGFloat = 8.0
    public var nodePadding: CGFloat {
        return lineWidth + selectionPadding
    }
    
    public var selectionBGColor = UIColor(hex: 0x00BCD4, alpha: 0.1)
    public var selectionStrokeColor = UIColor(hex: 0x00BCD4)
    public var fontName: String?
    
    public var selectedNodeCandidates: [String]? {
        guard let index = manager.indexOfSelectedNode else { return nil }
        return manager.nodes[index].candidates.filter { $0.count == 1 }
    }
    
    open weak var candidatesView: KeyboardType? {
        didSet {
            candidatesView?.delegate = self
            candidatesView?.dataSource = self
        }
    }
    
    open weak var keyboardView: KeyboardType? {
        didSet {
            keyboardView?.delegate = self
            keyboardView?.dataSource = self
        }
    }
    
    public weak var selectedNodeLayer: CALayer?
    
    public let tapGestureRecognizer = UITapGestureRecognizer()
    public let longPressGestureRecognizer = UILongPressGestureRecognizer()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setUp()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setUp()
    }
    
    private func setUp() {
        clipsToBounds = true
        
        tapGestureRecognizer.addTarget(self, action: #selector(tapAction(_:)))
        tapGestureRecognizer.isEnabled = false
        addGestureRecognizer(tapGestureRecognizer)
        
        longPressGestureRecognizer.addTarget(self, action: #selector(longPressAction(_:)))
        longPressGestureRecognizer.isEnabled = false
        addGestureRecognizer(longPressGestureRecognizer)
        
        manager.renderer = self
    }
    
    // MARK: - Public
    
    override open func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        
        for ink in manager.ink {
            if let strokeInk = ink as? StrokeInk {
                guard rect.intersects(strokeInk.path.bounds) else { continue }
                strokeInk.path.lineWidth = lineWidth
                strokeInk.path.lineCapStyle = .round
                strokeInk.path.stroke()
            } else {
                // TODO: Add error handling
                let charInk = ink as! CharacterInk
                guard rect.intersects(charInk.frame) else { continue }
                
                guard let ctx = UIGraphicsGetCurrentContext() else { return }
                guard let image = getImage(for: charInk, strokeColor: UIColor.black) else { return }
                ctx.draw(image.cgImage!, in: charInk.frame)
            }
        }
        
        if let stroke = manager.buffer {
            stroke.lineWidth = lineWidth
            stroke.lineCapStyle = .round
            stroke.stroke()
        }
    }
    
    // MARK: - Node
    
    @discardableResult
    open func selectNode(at point: NSValue?) -> Node? {
        return selectNode(at: point?.cgPointValue)
    }
    
    @discardableResult
    open func selectNode(at point: CGPoint?) -> Node? {
        let node = manager.selectNode(at: point)
        display(node: node)
        return node
    }
    
    private func getImage(for charInk: CharacterInk, strokeColor: UIColor) -> UIImage? {
        let size = charInk.frame.height - selectionPadding * 2.0
        
        let font = (fontName != nil ?
            UIFont(name: fontName!, size: size) :
            UIFont.systemFont(ofSize: size)) ?? UIFont.systemFont(ofSize: size)
        let attrib = [NSAttributedString.Key.font: font,
                      NSAttributedString.Key.foregroundColor: strokeColor]
        let attribString = NSAttributedString(string: String(charInk.character),
                                              attributes: attrib)
        
        let line = CTLineCreateWithAttributedString(attribString as CFAttributedString)
        var frame = CTLineGetImageBounds(line, nil)
        
        frame.size.width += abs(frame.origin.x)
        frame.size.height += abs(frame.origin.y)
        
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
        guard let fontCtx = UIGraphicsGetCurrentContext() else { return nil }
        fontCtx.textPosition = CGPoint(x: -frame.origin.x, y: -frame.origin.y)
        
        CTLineDraw(line, fontCtx)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    open func image(for node: Node) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(node.frame.size, false, 0.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.saveGState()
        
        ctx.setFillColor(selectionBGColor.cgColor)
        ctx.setStrokeColor(selectionStrokeColor.cgColor)
        ctx.fill(CGRect(origin: CGPoint.zero, size: node.frame.size))
        ctx.translateBy(x: -node.frame.origin.x, y: -node.frame.origin.y)
        
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.round)
        
        for ink in node.ink {
            if let strokeInk = ink as? StrokeInk {
                ctx.addPath(strokeInk.path.cgPath)
            } else {
                let charInk = ink as! CharacterInk
                guard let image = getImage(for: charInk, strokeColor: selectionStrokeColor)?.cgImage else {
                    return nil
                }
                ctx.draw(image, in: charInk.frame)
            }
        }
        
        ctx.strokePath()
        
        ctx.restoreGState()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()

        return image
    }
    
    // TODO: Add error handling
    
    open func display(node: Node?) {
        selectedNodeLayer?.removeFromSuperlayer()
        candidatesView?.hideKeyboard(nil)
        
        guard let node = node else { return }
        
        // Draw image of strokes and the bounding box
        
        // Set as layer content and assign `selectedNodeLayer`
        guard let image = image(for: node) else { return }
        
        let imageLayer = CALayer()
        imageLayer.frame = node.frame
        imageLayer.contents = image.cgImage
        
        // Add as sublayer
        layer.addSublayer(imageLayer)
        selectedNodeLayer = imageLayer
    }
    
    // MARK: - Touch
    
    private func register(touch: UITouch, isLast: Bool = false) {
        let rect = manager.inputStream(at: touch.location(in: self),
                                       previousPoint: touch.previousLocation(in: self),
                                       isLast: isLast)
        setNeedsDisplay(rect)
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isWritingMode else { return }
        register(touch: touches.first!)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isWritingMode { isWritingMode = true }
        register(touch: touches.first!)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isWritingMode else { return }
        register(touch: touches.first!, isLast: true)
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isWritingMode else { return }
        register(touch: touches.first!, isLast: true)
    }
    
    // MARK: - Target action
    
    @objc open func tapAction(_ sender: UITapGestureRecognizer) {
        let node = manager.selectNode(at: sender.location(in: self))
        
        display(node: node)
        delegate?.mathInputView(self, didTap: ObjCNode(node: node))
    }
    
    @objc open func longPressAction(_ sender: UILongPressGestureRecognizer) {
        let node = manager.selectNode(at: sender.location(in: self))
        
        display(node: node)
        delegate?.mathInputView(self, didLongPress: ObjCNode(node: node))
    }
    
    @IBAction open func undoAction(_ sender: UIButton?) {
        if !isWritingMode { isWritingMode = true }
        if let rect = manager.undo() {
            setNeedsDisplay(rect)
        }
    }
    
    @IBAction open func redoAction(_ sender: UIButton?) {
        if !isWritingMode { isWritingMode = true }
        if let rect = manager.redo() {
            setNeedsDisplay(rect)
        }
    }
    
    open func removeSelection() {
        guard let node = manager.removeSelectedNode() else { return }
        
        display(node: nil)
        setNeedsDisplay(node.frame)
        delegate?.mathInputView(self, didRemove: ObjCNode(node: node)!)
    }
    
    open func replaceSelection(with character: String) {
        guard let node = manager.replaceSelectedNode(with: character) else { return }
        
        display(node: nil)
        setNeedsDisplay(node.1.frame)
        delegate?.mathInputView(self, didReplace: ObjCNode(node: node.0)!, with: ObjCNode(node: node.1)!)
    }
    
    // MARK: - Keyboard
    
    open func keyboard(_ keyboard: KeyboardType, didReceive input: String?) {
        if let input = input {
            guard input.count == 1 else { return }
            replaceSelection(with: input)
        } else {
            removeSelection()
        }
    }
    
    // MARK: - MathInkRendering
    
    open func manager(_ manager: MathInkManager, didExtractLaTeX string: String) {
        delegate?.mathInputView(self, didParse: manager.ink, latex: string)
    }
    
    open func manager(_ manager: MathInkManager, didFailToExtractWith error: NSError) {
        delegate?.mathInputView(self, didFailToParse: manager.ink, with: error)
    }
    
    open func manager(_ manager: MathInkManager, didUpdateHistory state: (undo: Bool, redo: Bool)) {
        
    }
    
    open func manager(_ manager: MathInkManager, didScratchOut frame: CGRect) {
        
    }
    
    open func manager(_ manager: MathInkManager, didLoad ink: [InkType]?) {
        selectedNodeLayer?.removeFromSuperlayer()
        candidatesView?.hideKeyboard(nil)
        
        setNeedsDisplay()
    }
    
}


