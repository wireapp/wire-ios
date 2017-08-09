//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireTesting
@testable import WireDataModel

@objc public class DatabaseBaseTest: ZMTBaseTest {
    
    public var applicationContainer: URL {
        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("StorageStackTests")
    }

    override public func setUp() {
        super.setUp()
        self.clearStorageFolder()
        try! FileManager.default.createDirectory(at: self.applicationContainer, withIntermediateDirectories: true)
    }
    
    override public func tearDown() {
        StorageStack.reset()
        self.clearStorageFolder()
        super.tearDown()
    }
    
    /// Create storage stack
    func createStorageStackAndWaitForCompletion(
        userID: UUID = UUID()
        ) -> ManagedObjectContextDirectory
    {
        var contextDirectory: ManagedObjectContextDirectory? = nil
        
        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: userID,
            applicationContainer: self.applicationContainer
        ) { directory in
            contextDirectory = directory
        }
        
        guard self.waitOnMainLoop(until: { contextDirectory != nil }, timeout: 5) else {
            XCTFail()
            fatalError()
        }
        return contextDirectory!
    }
    
    /// Create storage stack at a legacy location
    @objc public func createLegacyStore(searchPath: FileManager.SearchPathDirectory) {
        let directory = FileManager.default.urls(for: searchPath, in: .userDomainMask).first!
        self.createLegacyStore(filePath: directory.appendingStoreFile())
    }
    
    /// Create storage stack at a legacy location
    @objc public func createLegacyStore(filePath: URL, customization: ((ManagedObjectContextDirectory)->())? = nil) {
        
        StorageStack.shared.createOnDiskStack(
            accountDirectory: filePath.deletingLastPathComponent(),
            storeFile: filePath,
            applicationContainer: self.applicationContainer,
            migrateIfNeeded: false,
            completionHandler: { mocs in
                customization?(mocs)
        })
        
        StorageStack.reset()
        self.createDummyExternalSupportFileForDatabase(storeFile: filePath)
    }
    
    /// Clears the current storage folder and the legacy locations
    public func clearStorageFolder() {
        let url = self.applicationContainer
        try? FileManager.default.removeItem(at: url)
        
        self.previousDatabaseLocations.forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }
    
    /// Creates some dummy Core Data store support file
    func createDummyExternalSupportFileForDatabase(storeFile: URL) {
        let storeName = storeFile.deletingPathExtension().lastPathComponent
        let supportPath = storeFile.deletingLastPathComponent().appendingPathComponent(".\(storeName)_SUPPORT")
        try! FileManager.default.createDirectory(at: supportPath, withIntermediateDirectories: true)
        try! self.mediumJPEGData().write(to: supportPath.appendingPathComponent("image.dat"))
    }
    
    /// Extensions after the database file name
    /// This is needed to expose Swift-only property to Obj-c
    public static var databaseFileExtensions: [String] {
        return PersistentStoreRelocator.storeFileExtensions
    }
    
    /// Previous locations where the database was stored
    var previousDatabaseLocations: [URL] {
        return [
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!,
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!,
            self.applicationContainer
        ]
    }
}
