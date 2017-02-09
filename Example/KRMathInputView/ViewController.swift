//
//  ViewController.swift
//  KRMathInputView
//
//  Created by BridgeTheGap on 02/09/2017.
//  Copyright (c) 2017 BridgeTheGap. All rights reserved.
//

import UIKit
import KRMathInputView

class MyScriptView: MathInputView {
    override func manager(_ manager: MathInkManager, didUpdateHistory state: (undo: Bool, redo: Bool)) {
        undoButton?.isEnabled = state.undo
        undoButton?.alpha = state.undo ? 1.0 : 0.7
        
        redoButton?.isEnabled = state.redo
        redoButton?.alpha = state.redo ? 1.0 : 0.7
    }
}

class ViewController: UIViewController, MathInputViewDelegate {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var mathInputView: MyScriptView!
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mathInputView.undoButton?.isEnabled = false
        mathInputView.undoButton?.alpha = 0.7
        
        mathInputView.redoButton?.isEnabled = false
        mathInputView.redoButton?.alpha = 0.7
        
        // FIXME: Set parser
//        mathInputView.manager.parser =
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - MathInputView delegate
    
    func mathInputView(_ MathInputView: MathInputView, didParse ink: [Any], latex: String) {
        print(latex)
    }
    
    func mathInputView(_ MathInputView: MathInputView, didFailToParse ink: [Any], with error: NSError) {
        print(error)
    }
    
}
