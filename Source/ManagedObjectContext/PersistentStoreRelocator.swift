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

public extension FileManager {
    
    fileprivate static func previousStoreURLs(sharedContainerURL: URL) -> [URL]  {
        var locations = [.cachesDirectory, .applicationSupportDirectory].flatMap{
            FileManager.default.urls(for: $0, in: .userDomainMask).first!
        }
        locations.append(sharedContainerURL)
        return locations.map{$0.appendingStorePath()}
    }

    /// Returns the URL for the current persistentStore
    public static func currentStoreURLForAccount(with accountIdentifier: UUID?, in sharedContainerURL: URL) -> URL {
        var url = sharedContainerURL
        if let accountIdentifier = accountIdentifier {
            url.appendPathComponent(accountIdentifier.uuidString, isDirectory:true)
        }
        return url.appendingStorePath()
    }
}


extension NSURL {
    /// Appends the path to the persistentStore in the form baseURL/{bundleId}/store.wiredatabase
    @objc(URLByAppendingStorePath)
    public func appendingStorePath() -> NSURL {
        return (self as URL).appendingStorePath() as NSURL
    }
}


extension URL {
    /// Appends the path to the persistentStore in the form baseURL/{bundleId}/store.wiredatabase
    public func appendingStorePath() -> URL {
        let bundleId = Bundle.main.bundleIdentifier ?? Bundle(for: ZMUser.self).bundleIdentifier
        require(nil != bundleId, "Bundle identifier not found")
        
        return appendingPathComponent(bundleId!, isDirectory: true).appendingPathComponent("store.wiredatabase", isDirectory: false)
    }
    
    fileprivate func appendingSuffixToLastPathComponent(suffix: String) -> URL {
        let modifiedComponent = lastPathComponent + suffix
        return deletingLastPathComponent().appendingPathComponent(modifiedComponent)
    }
}


@objc public class PersistentStoreRelocator : NSObject {
    
    private let zmLog = ZMSLog(tag: "PersistentStoreRelocator")
    
    let storeLocation : URL
    let previousStoreLocation : URL?
    static private let storeFileExtensions = ["", "-wal", "-shm"]

    public init(sharedContainerURL: URL, newStoreURL: URL) {
        self.storeLocation = newStoreURL
        self.previousStoreLocation = type(of:self).oldLocationForStore(sharedContainerURL: sharedContainerURL,
                                                                       newLocation: newStoreURL)
    }
    
    static func oldLocationForStore(sharedContainerURL: URL, newLocation: URL) -> URL? {
        let previousStoreLocations = FileManager.previousStoreURLs(sharedContainerURL: sharedContainerURL)
        return previousStoreLocations.first(where: { $0 != newLocation && storeExists(at: $0)})
    }
    
    func moveStoreIfNecessary() throws {
        if let previousStoreLocation = previousStoreLocation {
            try moveStore(from: previousStoreLocation, to: storeLocation)
        }
    }
    
    func moveStore(from: URL, to: URL) throws {
        guard type(of:self).storeExists(at: from) else {
            zmLog.debug("Attempt to move store from \(from.path), which doesn't exist")
            return
        }
        
        let fileManager = FileManager.default
        
        try type(of:self).storeFileExtensions.forEach { storeFileExtension in
            let destination = to.appendingSuffixToLastPathComponent(suffix: storeFileExtension)
            let source = from.appendingSuffixToLastPathComponent(suffix: storeFileExtension)
            
            if !fileManager.fileExists(atPath: source.path) {
                return
            }
            
            try fileManager.moveItem(at: source, to: destination)
        }
        
        try moveExternalBinaryStoreFiles(from: from, to: to)
    }
    
    private func moveExternalBinaryStoreFiles(from: URL, to: URL) throws {
        let fromStoreDirectory = from.deletingLastPathComponent()
        
        var isDirectory : ObjCBool = false
        if !FileManager.default.fileExists(atPath: fromStoreDirectory.path, isDirectory: &isDirectory) && !isDirectory.boolValue {
            return
        }
        
        let fromStoreName = from.deletingPathExtension().lastPathComponent
        let fromSupportFile = ".\(fromStoreName)_SUPPORT"
        let source = fromStoreDirectory.appendingPathComponent(fromSupportFile)
        
        let destinationStoreName = from.deletingPathExtension().lastPathComponent
        let destinationSupportFile = ".\(destinationStoreName)_SUPPORT"
        let destination = to.deletingLastPathComponent().appendingPathComponent(destinationSupportFile)
        
        try FileManager.default.moveItem(at: source, to: destination)
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

