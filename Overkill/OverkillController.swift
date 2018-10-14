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
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var blackListedProcessNames: [String] = []
    var overkillIsPaused = false
    let USERDEFAULTSPROCESSNAMES = "blacklistedProcessNames"
    let USERDEFAULTSFIRSTTIME = "firstLaunchForOverkill"

    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu

        if let blackListedProcessNames = UserDefaults.standard.array(forKey: USERDEFAULTSPROCESSNAMES) {
            self.blackListedProcessNames = blackListedProcessNames as! [String]
        } else {
            blackListedProcessNames = ["com.apple.iTunes"]
        }
        
        refreshStartAtLoginState()

        startListening()
        
        // First time app launch, let's show the settings screen
        if UserDefaults.standard.bool(forKey: USERDEFAULTSFIRSTTIME) == false {
            didClickPreferences(self)
            UserDefaults.standard.set(true, forKey: USERDEFAULTSFIRSTTIME)
        }
    }

    @IBAction func didClickPreferences(_ sender: Any) {
        if (preferencesWindow != nil) {
            preferencesWindow.window?.close()
            preferencesWindow = nil
        }
        preferencesWindow = PreferencesWindow()
        preferencesWindow.blackListedProcessNames = blackListedProcessNames
        preferencesWindow.appIsInAutostart = applicationIsInStartUpItems()
        preferencesWindow.showWindow(nil)
        preferencesWindow.delegate = self
        preferencesWindow.window?.makeKeyAndOrderFront(self)
    }

    @IBAction func didClickExit(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

    func preferencesDidUpdate(blackListedProcessNames: Array<String>) {
        self.blackListedProcessNames = blackListedProcessNames
        UserDefaults.standard.setValue(blackListedProcessNames, forKey: USERDEFAULTSPROCESSNAMES)

        killRunningApps()
    }

    func startListening() {
        let n = NSWorkspace.shared.notificationCenter
        n.addObserver(self, selector: #selector(appWillLaunch(note:)),
                      name: NSWorkspace.willLaunchApplicationNotification,
                      object: nil)

        killRunningApps()
    }

    func stopListening() {
        let n = NSWorkspace.shared.notificationCenter
        n.removeObserver(self, name: NSWorkspace.willLaunchApplicationNotification, object: nil)
    }

    func killRunningApps() {
        let runningApplications = NSWorkspace.shared.runningApplications
        for currentApplication in runningApplications.enumerated() {
            let runningApplication = runningApplications[currentApplication.offset]

            if (runningApplication.activationPolicy == .regular) { // normal macOS application
                if (blackListedProcessNames.contains(runningApplication.bundleIdentifier!)) {
                    killProcess(Int(runningApplication.processIdentifier))
                }
            }
        }
    }

    @objc func appWillLaunch(note: Notification) {
        if let processBundleIdentifier: String = note.userInfo?["NSApplicationBundleIdentifier"] as? String { // the bundle identifier
            if let processId = note.userInfo?["NSApplicationProcessIdentifier"] as? Int { // the pid
                if (blackListedProcessNames.contains(processBundleIdentifier)) {
                    killProcess(processId)
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
        overkillIsPaused = !overkillIsPaused

        if (overkillIsPaused) {
            stopListening()
            pauseButton.title = "Resume Overkill"
        } else {
            startListening()
            pauseButton.title = "Pause Overkill"
        }
    }
    
    @IBAction func didClickStartAtLogin(_ sender: Any) {
        toggleLaunchAtStartup()
        refreshStartAtLoginState()
    }
    
    func preferencesDidUpdateAutoLaunch() {
        didClickStartAtLogin(self)
    }
    
    func refreshStartAtLoginState() {
        startAtLoginMenuItem.state = applicationIsInStartUpItems() ? .on : .off
    }
}
