//
//  AppDelegate.swift
//  Overkill
//
//  Created by Felix Krause on 8/12/17.
//  Copyright © 2017 Felix Krause. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)


    @IBAction func didClickExit(_ sender: Any) {
        NSApplication.shared().terminate(self)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.title = "Overkill"
        statusItem.menu = statusMenu
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

