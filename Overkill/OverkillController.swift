//
//  OverkillController.swift
//  Overkill
//
//  Created by Felix Krause on 8/12/17.
//  Copyright © 2017 Felix Krause. All rights reserved.
//

import Cocoa

class OverkillController: NSObject, PreferencesWindowDelegate {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var pauseButton: NSMenuItem!

    var preferencesWindow: PreferencesWindow!
    @IBOutlet weak var startAtLoginMenuItem: NSMenuItem!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    var blackListedProcessNames: [String] = []
    var overkillIsPaused = false
    let USERDEFAULTSPROCESSNAMES = "blacklistedProcessNames"

    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu

        if let blackListedProcessNames = UserDefaults.standard.array(forKey: USERDEFAULTSPROCESSNAMES) {
            self.blackListedProcessNames = blackListedProcessNames as! [String]
        } else {
            self.blackListedProcessNames = ["com.apple.iTunes"]
        }
        
        self.refreshStartAtLoginState()

        startListening()
    }

    @IBAction func didClickPreferences(_ sender: Any) {
        if (preferencesWindow != nil) {
            preferencesWindow.window?.close()
            preferencesWindow = nil
        }
        self.preferencesWindow = PreferencesWindow()
        preferencesWindow.blackListedProcessNames = self.blackListedProcessNames
        preferencesWindow.appIsInAutostart = applicationIsInStartUpItems()
        preferencesWindow.showWindow(nil)
        preferencesWindow.delegate = self
        preferencesWindow.window?.makeKeyAndOrderFront(self)
    }

    @IBAction func didClickExit(_ sender: Any) {
        NSApplication.shared().terminate(self)
    }

    func preferencesDidUpdate(blackListedProcessNames: Array<String>) {
        self.blackListedProcessNames = blackListedProcessNames
        UserDefaults.standard.setValue(self.blackListedProcessNames, forKey: USERDEFAULTSPROCESSNAMES)

        self.killRunningApps()
    }

    func startListening() {
        let n = NSWorkspace.shared().notificationCenter
        n.addObserver(self, selector: #selector(self.appWillLaunch(note:)),
                      name: .NSWorkspaceWillLaunchApplication,
                      object: nil)

        self.killRunningApps()
    }

    func stopListening() {
        let n = NSWorkspace.shared().notificationCenter
        n.removeObserver(self, name: .NSWorkspaceWillLaunchApplication, object: nil)
    }

    func killRunningApps() {
        let runningApplications = NSWorkspace.shared().runningApplications
        for currentApplication in runningApplications.enumerated() {
            let runningApplication = runningApplications[currentApplication.offset]

            if (runningApplication.activationPolicy == .regular) { // normal macOS application
                if (self.blackListedProcessNames.contains(runningApplication.bundleIdentifier!)) {
                    self.killProcess(Int(runningApplication.processIdentifier))
                }
            }
        }
    }

    func appWillLaunch(note: Notification) {
        if let processBundleIdentifier: String = note.userInfo?["NSApplicationBundleIdentifier"] as? String { // the bundle identifier
            if let processId = note.userInfo?["NSApplicationProcessIdentifier"] as? Int { // the pid
                if (self.blackListedProcessNames.contains(processBundleIdentifier)) {
                    self.killProcess(processId)
                }
            }
        }
    }

    func killProcess(_ processId: Int) {
        if let process = NSRunningApplication.init(processIdentifier: pid_t(processId)) {
            print("Killing \(processId): \(String(describing: process.localizedName))")
            process.forceTerminate()
        }
    }

    @IBAction func didClickPause(_ sender: Any) {
        self.overkillIsPaused = !self.overkillIsPaused

        if (self.overkillIsPaused) {
            self.stopListening()
            self.pauseButton.title = "Resume Overkill"
        } else {
            self.startListening()
            self.pauseButton.title = "Pause Overkill"
        }
    }
    
    @IBAction func didClickStartAtLogin(_ sender: Any) {
        toggleLaunchAtStartup()
        refreshStartAtLoginState()
    }
    
    func preferencesDidUpdateAutoLaunch() {
        self.didClickStartAtLogin(self)
    }
    
    func refreshStartAtLoginState() {
        if (applicationIsInStartUpItems()) {
            self.startAtLoginMenuItem.state = 1
        } else {
            self.startAtLoginMenuItem.state = 0
        }
    }
}
