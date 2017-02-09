//
//  MathInputView.swift
//  TestScript
//
//  Created by Joshua Park on 31/01/2017.
//  Copyright © 2017 Knowre. All rights reserved.
//

import UIKit

@objc public protocol MathInputViewDelegate: NSObjectProtocol {
    func mathInputView(_ MathInputView: MathInputView, didParse ink: [Any], latex: String)
    func mathInputView(_ MathInputView: MathInputView, didFailToParse ink: [Any], with error: NSError)
}

open class MathInputView: UIView, MathInkManagerDelegate {
    public weak var delegate: MathInputViewDelegate?
    
    public var isWritingMode: Bool = true {
        willSet {
            tapGestureRecognizer.isEnabled = !newValue
            longPressGestureRecognizer.isEnabled = !newValue
        }
    }
    
    public var manager = MathInkManager()
    
    private let tapGestureRecognizer = UITapGestureRecognizer()
    private let longPressGestureRecognizer = UILongPressGestureRecognizer()
    
    
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
    }
    
    // MARK: - Public
    
    override open func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        
        for ink in manager.ink {
            if let strokeInk = ink as? StrokeInk, rect.intersects(strokeInk.path.bounds) {
                strokeInk.path.stroke()
            } else {
                
            }
        }
        
        if let stroke = manager.buffer { stroke.stroke() }
    }
    
    // MARK: - Private
    
    private func selectNode(at point: CGPoint) -> Node? {
        guard let node = manager.selectNode(at: point) else { return nil }
        displaySelection(at: node.frame)
        return node
    }
    
    private func displaySelection(at: CGRect) {
        // TODO: Implement
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
        register(touch: touches.first!)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        register(touch: touches.first!)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        register(touch: touches.first!, isLast: true)
        manager.process()
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    
    @IBAction public func undoAction(_ sender: UIButton) {
        if let rect = manager.undo() { setNeedsDisplay(rect) }
    }
    
    @IBAction public func redoAction(_ sender: UIButton) {
        if let rect = manager.redo() { setNeedsDisplay(rect) }
    }
    
    // MARK: - MyScriptParser delegate
    
    public func manager(_ manager: MathInkManager, didParseTreeToLaTex string: String) {
        delegate?.mathInputView(self, didParse: manager.ink, latex: string)
    }
    
    public func manager(_ manager: MathInkManager, didFailToParseWith error: NSError) {
        delegate?.mathInputView(self, didFailToParse: manager.ink, with: error)
    }
    
}
