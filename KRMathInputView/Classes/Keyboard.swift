//
//  Keyboard.swift
//  Pods
//
//  Created by Joshua Park on 23/02/2017.
//
//

import UIKit

public protocol KeyboardType: NSObjectProtocol {
    
    weak var delegate: KeyboardTypeDelegate? { get set }
    weak var dataSource: KeyboardTypeDataSource? { get set }
    
    func showKeyboard(_ sender: Any?)
    func hideKeyboard(_ sender: Any?)
    func reloadKeyboard()
    
}

public protocol KeyboardTypeDataSource: class {
    
    var selectedNodeCandidates: [String]? { get }
    
}

public protocol KeyboardTypeDelegate: class {
    
    func keyboard(_ keyboard: KeyboardType, didReceive input: String?)
    
}
