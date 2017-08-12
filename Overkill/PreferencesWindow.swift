//
//  PreferencesWindow.swift
//  Overkill
//
//  Created by Felix Krause on 8/12/17.
//  Copyright © 2017 Felix Krause. All rights reserved.
//

import Cocoa

protocol PreferencesWindowDelegate {
    func preferencesDidUpdate(blackListedProcessNames:Array<String>)
}

class PreferencesWindow: NSWindowController, NSWindowDelegate {
    var blackListedProcessNames: [String] = []
    var delegate: PreferencesWindowDelegate?

    override var windowNibName : String! {
        return "PreferencesWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func windowWillClose(_ notification: Notification) {
        self.delegate?.preferencesDidUpdate(blackListedProcessNames: self.blackListedProcessNames)
    }
}
