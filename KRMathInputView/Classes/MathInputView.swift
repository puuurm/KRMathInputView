//
//  MathInputView.swift
//  TestScript
//
//  Created by Joshua Park on 31/01/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

@objc public protocol MathInputViewDelegate: NSObjectProtocol {
    func mathInputView(_ mathInputView: MathInputView, didParse ink: [Any], latex: String)
    func mathInputView(_ mathInputView: MathInputView, didFailToParse ink: [Any], with error: NSError)
    func mathInputView(_ mathInputView: MathInputView, didChangeModeTo isWritingMode: Bool)
}

open class MathInputView: UIView, MathInkManagerDelegate, MathInkManagerDataSource {
    open weak var delegate: MathInputViewDelegate?
    
    public var isWritingMode: Bool = true {
        willSet {
            tapGestureRecognizer.isEnabled = !newValue
            longPressGestureRecognizer.isEnabled = !newValue
            
            if !isWritingMode && newValue { selectNode(at: nil) }
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
    
    public var selectionBGColor = UIColor(hex: 0x00BCD4, alpha: 0.1)
    public var selectionStrokeColor = UIColor(hex: 0x00BCD4)
    
    private weak var selectedNodeLayer: CALayer?
    
    private let tapGestureRecognizer = UITapGestureRecognizer()
    private let longPressGestureRecognizer = UILongPressGestureRecognizer()
    
    private let drawingQueue = DispatchQueue(label: "com.knowre.KRMathInputView.drawingQueue",
                                             qos: DispatchQoS.userInitiated)
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setUp()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setUp()
    }
    
    private func setUp() {
        tapGestureRecognizer.addTarget(self, action: #selector(tapAction(_:)))
        tapGestureRecognizer.isEnabled = false
        addGestureRecognizer(tapGestureRecognizer)
        
        longPressGestureRecognizer.addTarget(self, action: #selector(longPressAction(_:)))
        longPressGestureRecognizer.isEnabled = false
        addGestureRecognizer(longPressGestureRecognizer)
        
        manager.delegate = self
        manager.dataSource = self
    }
    
    // MARK: - Public
    
    override open func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        
        for ink in manager.ink {
            if let strokeInk = ink as? StrokeInk, rect.intersects(strokeInk.path.bounds) {
                strokeInk.path.stroke()
            } else {
                // TODO: Implement
            }
        }
        
        if let stroke = manager.buffer { stroke.stroke() }
    }
    
    // MARK: - Private
    
    @discardableResult
    private func selectNode(at point: CGPoint?) -> Node? {
        let node = manager.selectNode(at: point)
        display(node: node)
        return node
    }
    
    private func display(node: Node?) {
        selectedNodeLayer?.removeFromSuperlayer()
        
        guard let node = node else { return }
        
        drawingQueue.sync {
            var image: CGImage?
            
            // Draw image of strokes and the bounding box
            if let arrStrokeInk = node.ink as? [StrokeInk] {
                UIGraphicsBeginImageContextWithOptions(node.frame.size, false, 0.0)
                guard let ctx = UIGraphicsGetCurrentContext() else { return }
                ctx.saveGState()
                
                selectionBGColor.setFill()
                selectionStrokeColor.setStroke()
                
                ctx.fill(CGRect(origin: CGPoint.zero, size: node.frame.size))
                ctx.translateBy(x: -node.frame.origin.x, y: -node.frame.origin.y)
                ctx.setLineWidth(lineWidth)
                ctx.setLineCap(.round)
                
                for strokeInk in arrStrokeInk { ctx.addPath(strokeInk.path.cgPath) }
                
                ctx.strokePath()
                
                ctx.restoreGState()
                image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
                
                UIGraphicsEndImageContext()
            } else {
                // TODO: Implement CharacterInk drawing
            }
            
            // Set as layer content and assign `selectedNodeLayer`
            guard image != nil else { return }
            
            let imageLayer = CALayer()
            imageLayer.frame = node.frame
            imageLayer.contents = image
            
            DispatchQueue.main.async {
                // Add as sublayer
                self.layer.addSublayer(imageLayer)
                self.selectedNodeLayer = imageLayer
            }
        }
        
    }
    
    private func showMenu(at: CGRect) {
        
    }
    
    private func showCursor(at: CGRect) {
        
    }
    
    private func register(touch: UITouch, isLast: Bool = false) {
        let rect = manager.inputStream(at: touch.location(in: self),
                                       previousPoint: touch.previousLocation(in: self),
                                       isLast: isLast)
        setNeedsDisplay(rect)
    }
    
    // MARK: - Touch
    
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
        manager.process()
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isWritingMode else { return }
        register(touch: touches.first!, isLast: true)
        manager.process()
    }
    
    // MARK: - Target action
    
    @objc private func tapAction(_ sender: UITapGestureRecognizer) {
        guard let node = selectNode(at: sender.location(in: self)) else { return }
        showMenu(at: node.frame)
    }
    
    @objc private func longPressAction(_ sender: UILongPressGestureRecognizer) {
        guard let node = selectNode(at: sender.location(in: self)) else { return }
        showCursor(at: node.frame)
    }
    
    @IBAction open func undoAction(_ sender: UIButton?) {
        if !isWritingMode { isWritingMode = true }
        if let rect = manager.undo() { setNeedsDisplay(rect) }
    }
    
    @IBAction open func redoAction(_ sender: UIButton?) {
        if !isWritingMode { isWritingMode = true }
        if let rect = manager.redo() { setNeedsDisplay(rect) }
    }
    
    // MARK: - MyScriptParser delegate
    
    open func manager(_ manager: MathInkManager, didParseTreeToLaTex string: String) {
        delegate?.mathInputView(self, didParse: manager.ink, latex: string)
    }
    
    open func manager(_ manager: MathInkManager, didFailToParseWith error: NSError) {
        delegate?.mathInputView(self, didFailToParse: manager.ink, with: error)
    }
    
    open func manager(_ manager: MathInkManager, didUpdateHistory state: (undo: Bool, redo: Bool)) {
        
    }
}
