// Taken from https://gist.github.com/plapier/f8e1dde1b1624dfbb3e4

import Foundation

func applicationIsInStartUpItems() -> Bool {
    return itemReferencesInLoginItems().existingReference != nil
}

func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItem?, lastReference: LSSharedFileListItem?) {
    let appURL: URL = NSURL.fileURL(withPath: Bundle.main.bundlePath)
    guard let loginItemsRef = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList? else { return (nil, nil) }
    
    let loginItems: [LSSharedFileListItem] = (LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray).map { $0 as! LSSharedFileListItem }
    let lastItemRef: LSSharedFileListItem? = loginItems.last
    
    for currentItemRef in loginItems {
        guard let itemURL = LSSharedFileListItemCopyResolvedURL(currentItemRef, 0, nil) else { continue }
        guard (itemURL.takeRetainedValue() as URL) == appURL else { continue }
        return (currentItemRef, lastItemRef)
    }
    
    return (nil, lastItemRef)
}

func toggleLaunchAtStartup() {
    let itemReferences = itemReferencesInLoginItems()
    let shouldBeToggled = itemReferences.existingReference == nil
    guard let loginItemsRef = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList? else { return }
    if shouldBeToggled {
        let appUrl: CFURL = NSURL.fileURL(withPath: Bundle.main.bundlePath) as CFURL
        print("Add login item %@", appUrl)
        LSSharedFileListInsertItemURL(loginItemsRef, itemReferences.lastReference, nil, nil, appUrl, nil, nil)
    } else {
        if let itemRef = itemReferences.existingReference {
            print("Remove login item %@", itemRef)
            LSSharedFileListItemRemove(loginItemsRef, itemRef)
        }
    }
}
