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
    @IBOutlet weak var pauseButton: NSMenuItem!
    @IBOutlet weak var startAtLoginMenuItem: NSMenuItem!

    var preferencesWindow: PreferencesWindow!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
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
            self.blackListedProcessNames = ["com.apple.iTunes"]
        }
        
        self.refreshStartAtLoginState()

        startListening()
        
        // First time app launch, let's show the settings screen
        if UserDefaults.standard.bool(forKey: USERDEFAULTSFIRSTTIME) == false {
            self.didClickPreferences(self)
            UserDefaults.standard.set(true, forKey: USERDEFAULTSFIRSTTIME)
        }
    }

    @IBAction func didClickPreferences(_ sender: Any) {
        if preferencesWindow != nil {
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

    func startListening() {
        let notificationCenter = NSWorkspace.shared().notificationCenter
        notificationCenter.addObserver(self, selector: #selector(self.appWillLaunch(note:)),
                      name: .NSWorkspaceWillLaunchApplication,
                      object: nil)

        self.killRunningApps()
    }

    func stopListening() {
        let notificationCenter = NSWorkspace.shared().notificationCenter
        notificationCenter.removeObserver(self, name: .NSWorkspaceWillLaunchApplication, object: nil)
    }
    
    func killRunningApps() {
        let runningApplications = NSWorkspace.shared().runningApplications
        runningApplications.filter { $0.activationPolicy == .regular }  // normal macOS application
            .filter(self.containsBlackListedProcessName)
            .forEach(self.killProcess)
    }

    func appWillLaunch(note: Notification) {
        guard let processBundleIdentifier: String = note.userInfo?["NSApplicationBundleIdentifier"] as? String else { return } // the bundle identifier
        guard let processId = note.userInfo?["NSApplicationProcessIdentifier"] as? Int else { return } // the pid
        guard self.blackListedProcessNames.contains(processBundleIdentifier) else { return }
        guard let process = NSRunningApplication(processIdentifier: pid_t(processId)) else { return }
        self.killProcess(process)
    }
    
    private func containsBlackListedProcessName(_ application: NSRunningApplication) -> Bool {
        guard let bundleIdentifier = application.bundleIdentifier else { return false }
        return self.blackListedProcessNames.contains(bundleIdentifier)
    }
    
    private func killProcess(_ application: NSRunningApplication) {
        print("Killing \(application.processIdentifier): \(String(describing: application.localizedName))")
        application.forceTerminate()
    }

    @IBAction func didClickPause(_ sender: Any) {
        self.overkillIsPaused = !self.overkillIsPaused

        if self.overkillIsPaused {
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
    
    func refreshStartAtLoginState() {
        self.startAtLoginMenuItem.state = applicationIsInStartUpItems() ? 1 : 0
    }
}

extension OverkillController: PreferencesWindowDelegate {
    
    func preferencesDidUpdateAutoLaunch() {
        self.didClickStartAtLogin(self)
    }
    
    func preferencesDidUpdate(blackListedProcessNames: Array<String>) {
        self.blackListedProcessNames = blackListedProcessNames
        UserDefaults.standard.setValue(self.blackListedProcessNames, forKey: USERDEFAULTSPROCESSNAMES)
        
        self.killRunningApps()
    }
}
