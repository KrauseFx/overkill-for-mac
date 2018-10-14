//
//  PreferencesWindow.swift
//  Overkill
//
//  Created by Felix Krause on 8/12/17.
//  Copyright © 2017 Felix Krause. All rights reserved.
//

import Cocoa

protocol PreferencesWindowDelegate {
    func preferencesDidUpdate(blackListedProcessNames: [String])
    func preferencesDidUpdateAutoLaunch()
}

class PreferencesWindow: NSWindowController {
    
    // MARK - Properties
    
    @IBOutlet weak var applicationsTableView: NSTableView!
    @IBOutlet weak var startAtLoginButton: NSButton!

    var blackListedProcessNames = [String]()
    var appIsInAutostart: Bool = false
    var delegate: PreferencesWindowDelegate?

    override var windowNibName: String! {
        return "PreferencesWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        if appIsInAutostart {
            startAtLoginButton.state = .on
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction func didClickDone(_ sender: Any) {
        close()
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

        if (dialog.runModal() == .OK) {
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
                    blackListedProcessNames.append(bundleIdentifier)
                }
            }
        }

        applicationsTableView.reloadData()
        delegate?.preferencesDidUpdate(blackListedProcessNames: blackListedProcessNames)
    }
    
    override func cancelOperation(_ sender: Any?) {
        close()
    }

    @IBAction func didClickMinusButton(_ sender: Any) {
        if (applicationsTableView.selectedRow >= 0) {
            blackListedProcessNames.remove(at: applicationsTableView.selectedRow)
        }

        applicationsTableView.reloadData()
        delegate?.preferencesDidUpdate(blackListedProcessNames: blackListedProcessNames)
    }

    @IBAction func didClickStartAtLogin(_ sender: NSButton) {
        delegate?.preferencesDidUpdateAutoLaunch()
    }
    
    func windowWillClose(_ notification: Notification) {

    }
    @IBAction func didClickKrauseFxBestButtonIsBestButton(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://twitter.com/KrauseFx")!)
    }
    @IBAction func didClickOnDaniel(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://twitter.com/danielsinger")!)
    }
}

extension PreferencesWindow: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return blackListedProcessNames.count
    }
}

extension PreferencesWindow: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier.rawValue,
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier), owner: self) as? NSTableCellView else {
                return nil
        }
        cell.textField?.stringValue = identifier == "AutomaticTableColumnIdentifier.0" ? blackListedProcessNames[row] : ""
        return cell
    }
}
