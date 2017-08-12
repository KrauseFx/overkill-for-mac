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
    var blackListedProcessNames: [String] = []

    override func awakeFromNib() {
        statusItem.title = "Overkill"
        statusItem.menu = statusMenu
        
        self.blackListedProcessNames = ["iTunes", "Photos"] // TODO: move to preferences
        startListening()
    }

    @IBAction func didClickPreferences(_ sender: Any) {
        preferencesWindow = PreferencesWindow()
        preferencesWindow.showWindow(nil)
    }

    @IBAction func didClickExit(_ sender: Any) {
        NSApplication.shared().terminate(self)
    }
    
    func startListening() {
        let n = NSWorkspace.shared().notificationCenter
        n.addObserver(self, selector: #selector(self.appWillLaunch(note:)),
                      name: .NSWorkspaceWillLaunchApplication,
                      object: nil)
    }
    
    func appWillLaunch(note:Notification) {
        if let processName:String = note.userInfo?["NSApplicationName"] as? String {
            if let processId = note.userInfo?["NSApplicationProcessIdentifier"] as? Int {
                print(processName)
                if self.blackListedProcessNames.contains(processName) {
                    print("Killing " + processName)
                    self.killProcess(processId, processName)
                }
            }
        }
    }
    func killProcess(_ processId:Int,_ processName:String) {
        let process = NSRunningApplication.init(processIdentifier: pid_t(processId))
        process?.forceTerminate()
    }
}
