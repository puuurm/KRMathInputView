//
//  Keyboard.swift
//  Pods
//
//  Created by Joshua Park on 23/02/2017.
//
//

import UIKit

public protocol KeyboardType {
    
    weak var delegate: KeyboardTypeDelegate? { get }
    weak var dataSource: KeyboardTypeDataSource? { get }
    
    func showKeyboard(_ sender: Any?)
    func hideKeyboard(_ sender: Any?)
    func reloadKeyboard()
    
}

public protocol KeyboardTypeDataSource: class {
    
    func characters(for keyboard: KeyboardType) -> [Character]?
    
}

public protocol KeyboardTypeDelegate: class {
    
    func keyboard(_ keyboard: KeyboardType, didReceive input: Character?)
    
}
