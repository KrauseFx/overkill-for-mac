//
//  OverkillController.swift
//  Overkill
//
//  Created by Felix Krause on 8/12/17.
//  Copyright © 2017 Felix Krause. All rights reserved.
//

import Cocoa

class OverkillController: NSObject {
    
    // MARK - Properties

    private let USERDEFAULTSPROCESSNAMES = "blacklistedProcessNames"
    private let USERDEFAULTSFIRSTTIME = "firstLaunchForOverkill"
    
    @IBOutlet weak var statusMenu: NSMenu! {
        didSet {
            statusMenu.delegate = self
            statusItem.menu = statusMenu
        }
    }
    @IBOutlet weak var pauseButton: NSMenuItem!
    @IBOutlet weak var startAtLoginMenuItem: NSMenuItem!
    
    private var overkillIsPaused = false
    
    private lazy var preferencesWindow: PreferencesWindow = {
        let preferencesWindow = PreferencesWindow()
        preferencesWindow.blackListedProcessNames = blackListedProcessNames
        preferencesWindow.showWindow(nil)
        preferencesWindow.delegate = self
        preferencesWindow.window?.makeKeyAndOrderFront(self)
        return preferencesWindow
    }()
    
    private lazy var statusItem: NSStatusItem = {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        
        return statusItem
    }()
    
    private lazy var blackListedProcessNames: [String] = {
        guard let blackListedProcessNames = UserDefaults.standard.array(forKey: USERDEFAULTSPROCESSNAMES) as? [String] else {
            return ["com.apple.iTunes"]
        }
        return blackListedProcessNames
    }()
    
    // MARK - Lifecycle

    override func awakeFromNib() {
        startListening()
        configure()
    }
    
    // MARK: - Actions
    
    @IBAction func didClickPreferences(_ sender: Any) {
        showPreferences()
    }
    
    @IBAction func didClickExit(_ sender: Any) {
        NSApplication.shared.terminate(self)
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
    
    @IBAction func didClickStartAtLogin(_ sender: NSMenuItem) {
        toggleLaunchAtStartup()
        refreshStartAtLoginState()
    }
    
    // MARK: - Private functions
    
    private func startListening() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(self, selector: #selector(appWillLaunch(notification:)),
                                       name: NSWorkspace.willLaunchApplicationNotification,
                                       object: nil)
        
        killRunningApps()
    }
    
    private func stopListening() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.removeObserver(self, name: NSWorkspace.willLaunchApplicationNotification, object: nil)
    }
    
    private func killRunningApps() {
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
    
    @objc private func appWillLaunch(notification: Notification) {
        if let processBundleIdentifier: String = notification.userInfo?["NSApplicationBundleIdentifier"] as? String { // the bundle identifier
            if let processId = notification.userInfo?["NSApplicationProcessIdentifier"] as? Int { // the pid
                if (blackListedProcessNames.contains(processBundleIdentifier)) {
                    killProcess(processId)
                }
            }
        }
    }
    
    private func killProcess(_ processId: Int) {
        if let process = NSRunningApplication.init(processIdentifier: pid_t(processId)) {
            print("Killing \(processId): \(String(describing: process.localizedName!))")
            process.forceTerminate()
        }
    }
    
    private func configure() {
        if !UserDefaults.standard.bool(forKey: USERDEFAULTSFIRSTTIME) {
            UserDefaults.standard.set(true, forKey: USERDEFAULTSFIRSTTIME)
            refreshStartAtLoginState()
            showPreferences()
        }
    }
    
    private func showPreferences() {
        if !isPreferencesVisible() {
            preferencesWindow.showWindow(self)
            preferencesWindow.update(startAtLoginButton: applicationIsInStartUpItems() ? .on : .off)
            return
        }
    }
    
    private func isPreferencesVisible() -> Bool {
        return preferencesWindow.window?.occlusionState.contains(.visible) ?? false
    }
    
    private func refreshStartAtLoginState() {
        let state: NSControl.StateValue = applicationIsInStartUpItems() ? .on : .off
        startAtLoginMenuItem.state = state
        preferencesWindow.update(startAtLoginButton: state)
    }
}

extension OverkillController: PreferencesWindowDelegate {
    func preferencesDidUpdate(blackListedProcessNames: Array<String>) {
        self.blackListedProcessNames = blackListedProcessNames
        UserDefaults.standard.setValue(blackListedProcessNames, forKey: USERDEFAULTSPROCESSNAMES)
        killRunningApps()
    }
    
    func preferencesDidUpdateAutoLaunch() {
        toggleLaunchAtStartup()
        refreshStartAtLoginState()
    }
}

extension OverkillController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        startAtLoginMenuItem.state = applicationIsInStartUpItems() ? .on : .off
    }
}
