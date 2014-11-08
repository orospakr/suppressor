//
//  MyWindowController.swift
//  suppressor
//
//  Created by Andrew Clunis on 2014-11-04.
//  Copyright (c) 2014 Andrew Clunis. All rights reserved.
//

import Foundation

class MyWindowController : NSWindowController {

     override func  windowDidLoad() {
        super.windowDidLoad();
        
        self.window?.styleMask = (self.window?.styleMask)! | NSFullSizeContentViewWindowMask;
            
        
        // var mask : Word = ;
        
            //self.window?.styleMask | NSFullSizeContentViewWindowMask;
        self.window?.titlebarAppearsTransparent = true;
    }
}
