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

@objcMembers public class DatabaseBaseTest: ZMTBaseTest {
    
    var accountID : UUID = UUID.create()
    
    public var applicationContainer: URL {
        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("StorageStackTests")
    }

    override public func setUp() {
        super.setUp()
        self.clearStorageFolder()
        MainPersistentStoreRelocator.hostBundleIdentifier = Bundle.main.bundleIdentifier!
        try! FileManager.default.createDirectory(at: self.applicationContainer, withIntermediateDirectories: true)
        let legacyDatabaseDirectory = applicationContainer.appendingPathComponent(Bundle.main.bundleIdentifier!)
        try! FileManager.default.createDirectory(at: legacyDatabaseDirectory, withIntermediateDirectories: true)
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
            applicationContainer: self.applicationContainer,
            dispatchGroup: dispatchGroup
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
    @objc public func createLegacyStore(filePath: URL,
                                        customization: ((ManagedObjectContextDirectory)->())? = nil) {

        guard let persistentStoreCoordinator = try? NSPersistentStoreCoordinator.create(
                storeFile: filePath,
                applicationContainer: applicationContainer) else {
            return
        }

        let directory = ManagedObjectContextDirectory(
            persistentStoreCoordinator: persistentStoreCoordinator,
            accountDirectory: filePath.deletingLastPathComponent(),
            applicationContainer: self.applicationContainer)
        MemoryReferenceDebugger.register(directory)
        customization?(directory)

        StorageStack.reset()
        self.createDummyExternalSupportFileForDatabase(storeFile: filePath)
    }
    
    /// Create a session in the keystore directory for the given account
    public func createSessionInKeyStore(accountDirectory: URL, applicationContainer: URL, sessionId: EncryptionSessionIdentifier) {
        let preKey = "pQABAQICoQBYICHHDV4Zh6yJzJSPhQmtxah8N4kVE+XSCmTVfIsvgm5UA6EAoQBYIJeiWi5TfAWBrYSOtM5nKk5isfRYX5pFqRk13jVenPz6BPY="
        let keyStore = UserClientKeysStore(accountDirectory: accountDirectory, applicationContainer: applicationContainer)
        keyStore.encryptionContext.perform { sessionsDirectory in
            try! sessionsDirectory.createClientSession(sessionId, base64PreKeyString: preKey)
        }
    }
    
    /// Returns true if the given session exists in the keystore for the given account
    public func doesSessionExistInKeyStore(accountDirectory: URL, applicationContainer: URL, sessionId: EncryptionSessionIdentifier) -> Bool {
        
        var hasSession = false
        
        let keyStore = UserClientKeysStore(accountDirectory: accountDirectory, applicationContainer: applicationContainer)
        keyStore.encryptionContext.perform { sessionsDirectory in
            hasSession = sessionsDirectory.hasSession(for: sessionId)
        }
        
        return hasSession
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
            self.applicationContainer.appendingPathComponent(Bundle.main.bundleIdentifier!),
            self.applicationContainer.appendingPathComponent(Bundle.main.bundleIdentifier!).appendingPathComponent(accountID.uuidString).appendingPathComponent("store")
        ]
    }
    
    var previousDatabaseLocationsBeforeMultiAccountSupport: ArraySlice<URL> {
        return previousDatabaseLocations.prefix(3)
    }

    /// Previous locations where the keystore was stored
    var previousKeyStoreLocations: [URL] {
        return [
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!,
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!,
            self.applicationContainer,
            self.applicationContainer.appendingPathComponent(Bundle.main.bundleIdentifier!).appendingPathComponent(accountID.uuidString)
        ]
    }
}
