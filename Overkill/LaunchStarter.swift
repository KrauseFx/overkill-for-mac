// Taken from https://gist.github.com/plapier/f8e1dde1b1624dfbb3e4

import Foundation

// MARK - Public functions

func applicationIsInStartUpItems() -> Bool {
    return itemReferencesInLoginItems().existingReference != nil
}

func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItem?, lastReference: LSSharedFileListItem?) {
    let loginItemsRef = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue()
    
    guard let loginItems = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as? [LSSharedFileListItem],
        let lastItemRef = loginItems.last else {
            return (nil, nil)
    }
    
    let appURL = NSURL.fileURL(withPath: Bundle.main.bundlePath) as NSURL
    let currentItemRef = loginItems.first { currentItemRef in
        let itemURL = url(currentItemRef)
        return itemURL.isEqual(appURL)
    }
    
    return (currentItemRef, lastItemRef)
}

func toggleLaunchAtStartup() {
    let itemReferences = itemReferencesInLoginItems()
    let appUrl = NSURL.fileURL(withPath: Bundle.main.bundlePath)
    let loginItemsRef = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue()
    
    guard let existingReference = itemReferences.existingReference else {
        if let lastReference = itemReferences.lastReference {
            LSSharedFileListInsertItemURL(loginItemsRef, lastReference, nil, nil, appUrl as CFURL, nil, nil)
        }
        return
    }
    
    let itemURL = url(existingReference)
    LSSharedFileListItemRemove(loginItemsRef, get(item: itemURL))
}

// MARK - Private functions

private func get(item byURL: NSURL) -> LSSharedFileListItem? {
    let loginItemsRef = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue()
    
    guard let loginItems = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as? [LSSharedFileListItem] else {
        return nil
    }
    
    let item = loginItems.first { currentItemRef in
        let itemURL = url(currentItemRef)
        return itemURL.isEqual(byURL)
    }
    return item
}

private func url(_ item: LSSharedFileListItem?) -> NSURL {
    return LSSharedFileListItemCopyResolvedURL(item, 0, nil).takeRetainedValue() as NSURL
}

