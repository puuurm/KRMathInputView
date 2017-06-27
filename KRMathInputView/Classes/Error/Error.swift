//
//  Error.swift
//  Pods
//
//  Created by Joshua Park on 07/04/2017.
//
//

import Foundation

extension NSError {
    
    struct Domain: RawRepresentable {
        var rawValue: String
        
        static let inkManager = Domain(rawValue: "com.knowre.KRMathInputView.MathInkManager")
        
    }
    
    struct Code: RawRepresentable {
        var rawValue: Int
        
        
    }
    
    struct Description: RawRepresentable {
        var rawValue: String
        
        static func unknown(file: String, function: String, line: Int) -> Description {
            return Description(rawValue: "\(file):\(function)(\(line)): Unknown error.")
        }
    }
    
}

