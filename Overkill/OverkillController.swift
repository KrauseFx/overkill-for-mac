//
//  OverkillController.swift
//  Overkill
//
//  Created by Felix Krause on 8/12/17.
//  Copyright © 2017 Felix Krause. All rights reserved.
//

import Cocoa

class OverkillController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    var preferencesWindow: PreferencesWindow!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    override func awakeFromNib() {
        statusItem.title = "Overkill"
        statusItem.menu = statusMenu
    }
    

    @IBAction func didClickPreferences(_ sender: Any) {
        preferencesWindow = PreferencesWindow()
        preferencesWindow.showWindow(nil)
    }

    @IBAction func didClickExit(_ sender: Any) {
        NSApplication.shared().terminate(self)
    }
}
