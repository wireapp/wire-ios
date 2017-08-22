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

public struct MainPersistentStoreRelocator {
    /// Returns the list of possible locations for legacy stores
    static func possiblePreviousStoreFiles(applicationContainer: URL) -> [URL] {
        let locations = possibleLegacyAccountFolders(applicationContainer: applicationContainer)
        return locations.map{ $0.appendingStoreFile() }
    }
    
    static func possibleLegacyAccountFolders(applicationContainer: URL) -> [URL] {
        let sharedContainerAccountFolder = applicationContainer.appendingPathComponent(Bundle.main.bundleIdentifier!)
        return possibleCommonLegacyDirectories() + [sharedContainerAccountFolder]
    }

    static func possibleLegacyKeystoreFolders(applicationContainer: URL) -> [URL] {
        return possibleCommonLegacyDirectories() + [applicationContainer]
    }

    private static func possibleCommonLegacyDirectories() -> [URL] {
        return [.cachesDirectory, .applicationSupportDirectory, .libraryDirectory].map {
            FileManager.default.urls(for: $0, in: .userDomainMask).first!
        }
    }
    
    /// Return the first existing legacy store, if any
    static func exisingLegacyStore(applicationContainer: URL) -> URL? {
        let previousStoreLocations = self.possiblePreviousStoreFiles(applicationContainer: applicationContainer)
        return previousStoreLocations.first(where: { PersistentStoreRelocator.storeExists(at: $0)})
    }
    
    /// Relocates a legacy store to the new location, if necessary
    public static func moveLegacyStoreIfNecessary(
        storeFile: URL,
        applicationContainer: URL,
        startedMigrationCallback: (()->())?)
    {
        if let previousStoreLocation = self.exisingLegacyStore(applicationContainer: applicationContainer), previousStoreLocation != storeFile {
            startedMigrationCallback?()
            PersistentStoreRelocator.moveStore(from: previousStoreLocation, to: storeFile)
            deleteAllLegacyStoresExcept(storeFile: storeFile, applicationContainer: applicationContainer)
        }
    }
    
    /// Delete all other legacy stores except for the given legacy store.
    private static func deleteAllLegacyStoresExcept(storeFile: URL, applicationContainer: URL) {
        
        for oldStore in possiblePreviousStoreFiles(applicationContainer: applicationContainer) {
            if PersistentStoreRelocator.storeExists(at: oldStore) && oldStore != storeFile {
                PersistentStoreRelocator.delete(storeFile: oldStore)
            }
        }
    }
    
    public static func needsToMoveLegacyStore(storeFile: URL, applicationContainer: URL) -> Bool {
        if let previousStoreLocation = self.exisingLegacyStore(applicationContainer: applicationContainer), previousStoreLocation != storeFile {
            return true
        } else {
            return false
        }
    }
}

/// Relocates a store and related files from one location to another
public struct PersistentStoreRelocator {
    
    private init() {}
    
    private static let zmLog = ZMSLog(tag: "PersistentStoreRelocator")
    private static let fileManager = FileManager.default
    
    /// Extension of store files
    public static let storeFileExtensions = ["", "-wal", "-shm"]
    
    public static func moveStore(from: URL, to: URL) {
        guard self.storeExists(at: from) else {
            zmLog.debug("Attempt to move store from \(from.path), which doesn't exist")
            return
        }

        fileManager.createAndProtectDirectory(at: to.deletingLastPathComponent())
        moveExternalBinaryStoreFilesIfNeeded(from: from, to: to)
        
        self.storeFileExtensions.reversed().forEach { storeFileExtension in
            let destination = to.appendingSuffixToLastPathComponent(suffix: storeFileExtension)
            let source = from.appendingSuffixToLastPathComponent(suffix: storeFileExtension)
            
            if !fileManager.fileExists(atPath: source.path) {
                return
            }
            
            if fileManager.fileExists(atPath: destination.path) {
                try! fileManager.removeItem(at: destination)
            }
            try! fileManager.moveItem(at: source, to: destination)
        }
    }
    
    private static func moveExternalBinaryStoreFilesIfNeeded(from: URL, to: URL) {
        do {
            guard fileManager.fileExists(atPath: from.supportFolderForStoreFile.path) else { return }
            let toDirectory = to.deletingLastPathComponent()
            fileManager.createAndProtectDirectory(at: toDirectory)
            try FileManager.default.moveFolderRecursively(from: from.supportFolderForStoreFile, to: to.supportFolderForStoreFile, overwriteExistingFiles: false)
        } catch {
            fatal("Failed to move existing binary store file from \(from) to \(to): \(error)")
        }
    }
    
    public static func storeExists(at url: URL) -> Bool {
        let fileManager = FileManager.default
        let storeFiles = storeFileExtensions.map(url.appendingSuffixToLastPathComponent(suffix:))
        let storeFilesExists = storeFiles.reduce(false, { (result, url) in
            return result || fileManager.fileExists(atPath: url.path)
        })
        
        return storeFilesExists || externalBinaryStoreFileExists(at: url)
    }
    
    static func externalBinaryStoreFileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.supportFolderForStoreFile.path)
    }
    
    /// Deletes the store files and the associated support folder.
    fileprivate static func delete(storeFile: URL) {
        
        let fileManager = FileManager.default
        
        self.storeFileExtensions.forEach {
            do {
                try fileManager.removeItem(at: storeFile.appendingSuffixToLastPathComponent(suffix: $0))
            } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
                // nop
            } catch {
                fatal("Unexpected error deleting store file \($0): \(error)")
            }
        }
        
        do {
            try fileManager.removeItem(at: storeFile.supportFolderForStoreFile)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
            // nop
        } catch {
            fatal("Unexpected error deleting store file from \(storeFile.supportFolderForStoreFile): \(error)")
        }
    }
}

extension URL {
    
    var supportFolderForStoreFile: URL {
        let storeName = self.deletingPathExtension().lastPathComponent
        let storeDirectory = self.deletingLastPathComponent()
        let supportFile = ".\(storeName)_SUPPORT"
        return storeDirectory.appendingPathComponent(supportFile)
    }
}
