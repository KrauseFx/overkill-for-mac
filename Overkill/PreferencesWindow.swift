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

class PreferencesWindow: NSWindowController, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var applicationsTableView: NSTableView!

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
    
    @IBAction func didClickPlusButton(_ sender: Any) {
        let dialog = NSOpenPanel();
        
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
                self.blackListedProcessNames.append(bundleIdentifier)
            }
        }
        
        self.applicationsTableView.reloadData()
        self.delegate?.preferencesDidUpdate(blackListedProcessNames: self.blackListedProcessNames)
    }
    
    @IBAction func didClickMinusButton(_ sender: Any) {
        if (self.applicationsTableView.selectedRow >= 0) {
            self.blackListedProcessNames.remove(at: self.applicationsTableView.selectedRow)
        }
        
        self.applicationsTableView.reloadData()
        self.delegate?.preferencesDidUpdate(blackListedProcessNames: self.blackListedProcessNames)
    }
    
    func windowWillClose(_ notification: Notification) {
        
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.blackListedProcessNames.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var result:NSTableCellView
        result  = tableView.make(withIdentifier: (tableColumn?.identifier)!, owner: self) as! NSTableCellView
        let column = (tableColumn?.identifier)!
        var txtValue = ""
        
        if (column == "AutomaticTableColumnIdentifier.0") {
            txtValue = ""
        }
        else if (column == "AutomaticTableColumnIdentifier.1") {
            txtValue = self.blackListedProcessNames[row] // bundle identifier
        } else if (column == "AutomaticTableColumnIdentifier.2") {
            // localised name
            txtValue = ""
        }
        
        result.textField?.stringValue = txtValue
        return result
    }
}
