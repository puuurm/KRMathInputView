//
//  KRStackView.swift
//  Pods
//
//  Created by Joshua Park on 7/13/16.
//
//

import UIKit

public enum StackDirection {
    case vertical
    case horizontal
}

public enum ItemAlignment {
    case origin
    case center
    case endPoint
}

extension CGRect {
    var endPoint: CGPoint {
        get {
            return CGPoint(x: origin.x + width, y: origin.y + height)
        }
    }
}

open class KRStackView: UIView {
    @IBInspectable open var enabled: Bool = true
    
    open var direction: StackDirection = .vertical
    
    @IBInspectable open var translatesCurrentLayout: Bool = false {
        didSet {
            if translatesCurrentLayout { alignment = .origin }
        }
    }

    open var insets: UIEdgeInsets = UIEdgeInsets.zero
    
    @IBInspectable open var spacing: CGFloat = 8.0
    open var itemSpacing: [CGFloat]?
    
    open var alignment: ItemAlignment = .origin
    open var itemOffset: [CGFloat]?
    
    @IBInspectable open var shouldWrap: Bool = false
    
    public init(frame: CGRect, subviews: [UIView]) {
        super.init(frame: frame)
        for view in subviews { addSubview(view) }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public convenience init(subviews: [UIView]) {
        self.init(frame: CGRect.zero, subviews: subviews)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func layoutSubviews() {
        guard enabled else { super.layoutSubviews(); return }
        guard subviews.count > 0 else { return }
        
        if translatesCurrentLayout { (itemSpacing, itemOffset) = ([CGFloat](), [CGFloat]()) }
        
        let isVertical = direction == .vertical

        if !translatesAutoresizingMaskIntoConstraints {
            NSLayoutConstraint.deactivate(constraints + superview!.constraints.filter{ $0.firstItem === self || $0.secondItem === self })
            translatesAutoresizingMaskIntoConstraints = true
            
            if translatesCurrentLayout {
                translateCurrentStateForSubviews()
            } else {
                for v in subviews { v.translatesAutoresizingMaskIntoConstraints = true }
            }
        } else if translatesCurrentLayout {
            translateCurrentStateForSubviews()
        }
        
        var endX: CGFloat!
        var endY: CGFloat!
        
        if isVertical {
            var maxWidth = subviews[0].frame.width + (itemOffset?[0] ?? 0.0)
            for (i, view) in subviews.enumerated() {
                if maxWidth < view.frame.width + (itemOffset?[i] ?? 0.0) {
                    maxWidth = view.frame.width + (itemOffset?[i] ?? 0.0)
                }
            }
            let maxX = insets.left + maxWidth + insets.right
            
            endX = shouldWrap ? maxX : max(maxX, frame.width)
            endY = 0.0
        } else {
            endX = 0.0
            
            var maxHeight = subviews[0].frame.height + (itemOffset?[0] ?? 0.0)
            for (i, view) in subviews.enumerated() {
                if maxHeight < view.frame.height + (itemOffset?[i] ?? 0.0) {
                    maxHeight = view.frame.height + (itemOffset?[i] ?? 0.0)
                }
            }
            let maxY = insets.top + maxHeight + insets.bottom
            
            endY = shouldWrap ? maxY : max(maxY, frame.height)
        }
        
        let useItemSpacing = itemSpacing != nil && itemSpacing!.count >= subviews.count - 1
        let useItemOffset = itemOffset != nil && itemOffset!.count >= subviews.count
        
        for (i, view) in subviews.enumerated() {
            if isVertical {
                view.frame.origin.y = i == 0 ? insets.top : useItemSpacing ? endY + itemSpacing![i-1] : endY + spacing
                endY = view.frame.endPoint.y
            } else {
                view.frame.origin.x = i == 0 ? insets.left : useItemSpacing ? endX + itemSpacing![i-1] : endX + spacing
                endX = view.frame.endPoint.x
            }
            
            switch alignment {
            case .origin:
                if isVertical {
                    view.frame.origin.x = useItemOffset ? insets.left + itemOffset![i] : insets.left
                } else {
                    view.frame.origin.y = useItemOffset ? insets.top + itemOffset![i] : insets.top
                }
            case .center:
                if isVertical {
                    view.center.x = useItemOffset ? round(endX/2.0) + itemOffset![i]/2.0 : round(endX/2.0)
                } else {
                    view.center.y = useItemOffset ? round(endY/2.0) + itemOffset![i]/2.0 : round(endY/2.0)
                }
            case .endPoint:
                if isVertical {
                    view.frame.origin.x = endX - (insets.right+view.frame.width)
                    if useItemOffset { view.frame.origin.x -= itemOffset![i] }
                } else {
                    view.frame.origin.y = endY - (insets.bottom+view.frame.height)
                    if useItemOffset { view.frame.origin.y -= itemOffset![i] }
                }
            }
        }
        
        if isVertical {
            frame.size.width = endX
            frame.size.height = shouldWrap ? endY + insets.bottom : max(endY + insets.bottom, frame.height)
        } else {
            frame.size.width = shouldWrap ? endX + insets.right : max(endX + insets.right, frame.width)
            frame.size.height = endY
        }
        
        defer { translatesCurrentLayout = false }
    }
    
    fileprivate func translateCurrentStateForSubviews() {
        for (i, view) in subviews.enumerated() {
            view.translatesAutoresizingMaskIntoConstraints = true
            
            if direction == .vertical {
                let origin = view.frame.origin
                if i == 0 { insets.top = origin.y }
                else { itemSpacing!.append(origin.y - subviews[i-1].frame.endPoint.y) }
                
                itemOffset!.append(origin.x)
            } else {
                let origin = view.frame.origin
                if i == 0 { insets.left = origin.x }
                else { itemSpacing!.append(origin.x - subviews[i-1].frame.endPoint.x) }
                
                itemOffset!.append(origin.y)
            }
        }
    }
}
