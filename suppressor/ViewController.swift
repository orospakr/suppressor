//
//  ViewController.swift
//  suppressor
//
//  Created by Andrew Clunis on 2014-11-01.
//  Copyright (c) 2014 Andrew Clunis. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    
    @IBOutlet weak var materialBackground: NSVisualEffectView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        materialBackground.material = NSVisualEffectMaterial.Titlebar;
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}
