//
//  PreferencesWindow.swift
//  Overkill
//
//  Created by Felix Krause on 8/12/17.
//  Copyright © 2017 Felix Krause. All rights reserved.
//

import Cocoa

protocol PreferencesWindowDelegate {
    func preferencesDidUpdate(blackListedProcessNames: Array<String>)
    func preferencesDidUpdateAutoLaunch()
}

class PreferencesWindow: NSWindowController, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var applicationsTableView: NSTableView!

    var blackListedProcessNames: [String] = []
    var appIsInAutostart: Bool = false
    var delegate: PreferencesWindowDelegate?

    @IBOutlet weak var startAtLoginButton: NSButton!

    override var windowNibName: String! {
        return "PreferencesWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        if appIsInAutostart {
            self.startAtLoginButton.state = NSControlStateValueOn
        }
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction func didClickDone(_ sender: Any) {
        self.close()
    }

    @IBAction func didClickPlusButton(_ sender: Any) {
        let dialog = NSOpenPanel()

        dialog.directoryURL = URL(string: "/Applications")
        dialog.title                   = "Choose an application"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["app"]

        if (dialog.runModal() == NSModalResponseOK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                var fullPath = (result!.absoluteString) + "/Contents/Info.plist"
                fullPath = fullPath.replacingOccurrences(of: "file://", with: "")
                let content = NSDictionary(contentsOfFile: fullPath)
                let bundleIdentifier = content?.value(forKey: "CFBundleIdentifier") as! String
                if (bundleIdentifier == "com.krausefx.Overkill") {
                    let alert = NSAlert()
                    alert.messageText = "Ouch..."
                    alert.informativeText = "Somewhere in the world, a Nokia phone just dropped... on another Nokia phone"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK, I feel ashamed, I'm sorry")
                    alert.runModal()
                } else {
                    self.blackListedProcessNames.append(bundleIdentifier)
                }
            }
        }

        self.applicationsTableView.reloadData()
        self.delegate?.preferencesDidUpdate(blackListedProcessNames: self.blackListedProcessNames)
    }
    
    override func cancelOperation(_ sender: Any?) {
        self.close()
    }

    @IBAction func didClickMinusButton(_ sender: Any) {
        if (self.applicationsTableView.selectedRow >= 0) {
            self.blackListedProcessNames.remove(at: self.applicationsTableView.selectedRow)
        }

        self.applicationsTableView.reloadData()
        self.delegate?.preferencesDidUpdate(blackListedProcessNames: self.blackListedProcessNames)
    }

    @IBAction func didClickStartAtLogin(_ sender: NSButton) {
        self.delegate?.preferencesDidUpdateAutoLaunch()
    }
    
    func windowWillClose(_ notification: Notification) {

    }
    @IBAction func didClickKrauseFxBestButtonIsBestButton(_ sender: Any) {
        NSWorkspace.shared().open(URL(string: "https://twitter.com/KrauseFx")!)
    }
    @IBAction func didClickOnDaniel(_ sender: Any) {
        NSWorkspace.shared().open(URL(string: "https://twitter.com/danielsinger")!)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.blackListedProcessNames.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var result: NSTableCellView
        result  = tableView.make(withIdentifier: (tableColumn?.identifier)!, owner: self) as! NSTableCellView
        let column = (tableColumn?.identifier)!
        var txtValue = ""

        if (column == "AutomaticTableColumnIdentifier.0") {
            txtValue = self.blackListedProcessNames[row] // bundle identifier
        }

        result.textField?.stringValue = txtValue
        return result
    }
}
