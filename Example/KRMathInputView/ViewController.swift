//
//  ViewController.swift
//  KRMathInputView
//
//  Created by BridgeTheGap on 02/09/2017.
//  Copyright (c) 2017 BridgeTheGap. All rights reserved.
//

import UIKit
import KRMathInputView

class ViewController: UIViewController, MathInputViewDelegate {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var mathInputView: MathInputView!
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mathInputView.delegate = self
        // FIXME: Set parser
//        mathInputView.manager.parser =
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func undoAction(_ sender: UIButton) {
        mathInputView.undoAction(sender)
    }
    
    @IBAction func redoAction(_ sender: UIButton) {
        mathInputView.redoAction(sender)
    }
    
    // MARK: - MathInputView delegate
    
    func mathInputView(_ MathInputView: MathInputView, didParse ink: [Any], latex: String) {
        print(latex)
    }
    
    func mathInputView(_ MathInputView: MathInputView, didFailToParse ink: [Any], with error: NSError) {
        print(error)
    }
    
}
