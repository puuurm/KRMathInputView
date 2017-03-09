//
//  UIBezierPath+Convenience.swift
//  Pods
//
//  Created by Joshua Park on 09/03/2017.
//
//

import UIKit

public extension UIBezierPath {
    public var points: [CGPoint] {
        var points = [CGPoint]()
        
        withUnsafeMutablePointer(to: &points) { pointer in
            cgPath.apply(info: pointer) {
                let element = $0.1.pointee
                let ptrPoints = $0.0!.assumingMemoryBound(to: [CGPoint].self)
                
                switch element.type {
                    
                case .moveToPoint, .addLineToPoint:
                    ptrPoints.pointee.append(element.points[0])
                    
                case .addQuadCurveToPoint:
                    ptrPoints.pointee.append(element.points[0])
                    ptrPoints.pointee.append(element.points[1])
                    
                case .addCurveToPoint:
                    ptrPoints.pointee.append(element.points[0])
                    ptrPoints.pointee.append(element.points[1])
                    ptrPoints.pointee.append(element.points[2])
                    
                default: break
                    
                }
            }
        }
        
        return points
    }
}
