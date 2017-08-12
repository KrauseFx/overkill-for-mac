//
//  PreferencesWindow.swift
//  Overkill
//
//  Created by Felix Krause on 8/12/17.
//  Copyright © 2017 Felix Krause. All rights reserved.
//

import Cocoa

class PreferencesWindow: NSWindowController, NSWindowDelegate {
    override var windowNibName : String! {
        return "PreferencesWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true) // TODO: what does this do
    }
    
    func windowWillClose(_ notification: Notification) {
//        let defaults = UserDefaults.standard
//        defaults.setValue(cityTextField.stringValue, forKey: "city")
    }
}
