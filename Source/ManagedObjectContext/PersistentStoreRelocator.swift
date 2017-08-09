//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

extension URL {

    /// Appends a suffix to the last path (e.g. from `/foo/bar` to `/foo/bar_1`)
    func appendingSuffixToLastPathComponent(suffix: String) -> URL {
        let modifiedComponent = lastPathComponent + suffix
        return deletingLastPathComponent().appendingPathComponent(modifiedComponent)
    }
    
    /// Appends the name of the store to the path
    func appendingStoreFile() -> URL {
        return self.appendingPathComponent("store.wiredatabase")
    }
}

/// Relocates a store from a folder to another
public struct PersistentStoreRelocator {
    
    private init() {}
    
    private static let zmLog = ZMSLog(tag: "PersistentStoreRelocator")
    
    /// Extension of store files
    public static let storeFileExtensions = ["", "-wal", "-shm"]
    
    /// Returns the list of possible locations for legacy stores
    static func possiblePreviousStoreFiles(applicationContainer: URL) -> [URL] {
        var locations = [.cachesDirectory, .applicationSupportDirectory].map{
            FileManager.default.urls(for: $0, in: .userDomainMask).first!
        }
        locations.append(applicationContainer)
        return locations.map{ $0.appendingStoreFile() }
    }
    
    /// Return the first existing legacy store, if any
    static func exisingLegacyStore(applicationContainer: URL) -> URL? {
        let previousStoreLocations = self.possiblePreviousStoreFiles(applicationContainer: applicationContainer)
        return previousStoreLocations.first(where: { storeExists(at: $0)})
    }
    
    /// Relocates a legacy store to the new location, if necessary
    public static func moveLegacyStoreIfNecessary(
        storeFile: URL,
        applicationContainer: URL,
        startedMigrationCallback: (()->())?)
    {
        if let previousStoreLocation = self.exisingLegacyStore(applicationContainer: applicationContainer), previousStoreLocation != storeFile {
            startedMigrationCallback?()
            self.moveStore(from: previousStoreLocation, to: storeFile)
        }
    }
    
    private static func moveStore(from: URL, to: URL) {
        guard self.storeExists(at: from) else {
            zmLog.debug("Attempt to move store from \(from.path), which doesn't exist")
            return
        }
        
        let fileManager = FileManager.default
        fileManager.createAndProtectDirectory(at: to.deletingLastPathComponent())
        
        self.storeFileExtensions.forEach { storeFileExtension in
            let destination = to.appendingSuffixToLastPathComponent(suffix: storeFileExtension)
            let source = from.appendingSuffixToLastPathComponent(suffix: storeFileExtension)
            
            if !fileManager.fileExists(atPath: source.path) {
                return
            }
            
            try! fileManager.moveItem(at: source, to: destination)
        }
        
        moveExternalBinaryStoreFiles(from: from, to: to)
    }
    
    private static func moveExternalBinaryStoreFiles(from: URL, to: URL) {
        let fromStoreDirectory = from.deletingLastPathComponent()
        
        let fromStoreName = from.deletingPathExtension().lastPathComponent
        let fromSupportFile = ".\(fromStoreName)_SUPPORT"
        let source = fromStoreDirectory.appendingPathComponent(fromSupportFile)

        var isDirectory : ObjCBool = false
        if !FileManager.default.fileExists(atPath: source.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
            return
        }

        let toDirectory = to.deletingLastPathComponent()
        FileManager.default.createAndProtectDirectory(at: toDirectory)
        
        let destinationStoreName = from.deletingPathExtension().lastPathComponent
        let destinationSupportFile = ".\(destinationStoreName)_SUPPORT"
        let destination = to.deletingLastPathComponent().appendingPathComponent(destinationSupportFile)
        
        try! FileManager.default.moveItem(at: source, to: destination)
    }
    
    static func storeExists(at url: URL) -> Bool {
        let fileManager = FileManager.default
        let storeFiles = storeFileExtensions.map(url.appendingSuffixToLastPathComponent(suffix:))
        let storeFilesExists = storeFiles.reduce(false, { (result, url) in
            return result || fileManager.fileExists(atPath: url.path)
        })
        
        return storeFilesExists || externalBinaryStoreFileExists(at: url)
    }
    
    static func externalBinaryStoreFileExists(at url: URL) -> Bool {
        let storeName = url.deletingPathExtension().lastPathComponent
        let storeDirectory = url.deletingLastPathComponent()
        let supportFile = ".\(storeName)_SUPPORT"
        
        var isDirectory : ObjCBool = false
        if !FileManager.default.fileExists(atPath: storeDirectory.path, isDirectory: &isDirectory) && !isDirectory.boolValue {
            return false
        }
        
        return FileManager.default.fileExists(atPath: storeDirectory.appendingPathComponent(supportFile).path)
    }
    
}

