//
//  UIColor+Convenience.swift
//  Pods
//
//  Created by Joshua Park on 17/02/2017.
//
//

import Foundation

internal extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((hex & 0xFF00) >> 8) / 255.0,
                  blue: CGFloat(hex & 0xFF) / 255.0,
                  alpha: alpha)
    }
}
