////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireUtilities

extension StorageStack {

    private static let metadataFilename = "export.json"
    private static let databaseDirectoryName = "data"
    
    // Each backup for any account will be created in a unique subdirectory inside.
    // Clearing this should remove all
    public static var backupsDirectory: URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return tempURL.appendingPathComponent("backups")
    }

    public enum BackupError: Error {
        case failedToRead
        case failedToWrite
    }
    
    public struct BackupInfo {
        public let url: URL
        public let metadata: BackupMetadata
    }

    /// Will make a copy of account storage and place in a unique directory
    ///
    /// - Parameters:
    ///   - accountIdentifier: identifier of account being backed up
    ///   - applicationContainer: shared application container
    ///   - dispatchGroup: group for testing
    ///   - completion: called on main thread when done. Result will contain the folder where all data was written to.
    public static func backupLocalStorage(accountIdentifier: UUID, clientIdentifier: String, applicationContainer: URL, dispatchGroup: ZMSDispatchGroup? = nil, completion: @escaping ((Result<BackupInfo>) -> Void)) {
        func fail(_ error: BackupError) {
            DispatchQueue.main.async {
                completion(.failure(error))
                dispatchGroup?.leave()
            }
        }

        dispatchGroup?.enter()
        let fileManager = FileManager()

        let accountDirectory = StorageStack.accountFolder(accountIdentifier: accountIdentifier, applicationContainer: applicationContainer)
        let storeFile = accountDirectory.appendingPersistentStoreLocation()

        guard fileManager.fileExists(atPath: accountDirectory.path) else { return fail(.failedToRead) }

        let queue = DispatchQueue(label: "Database export", qos: .userInitiated)

        let backupDirectory = backupsDirectory.appendingPathComponent(UUID().uuidString)
        let databaseDirectory = backupDirectory.appendingPathComponent(databaseDirectoryName)
        let metadataURL = backupDirectory.appendingPathComponent(metadataFilename)

        queue.async() {
            do {
                let model = NSManagedObjectModel.loadModel()
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

                // Create target directory
                try FileManager.default.createDirectory(at: databaseDirectory, withIntermediateDirectories: true, attributes: nil)
                let backupLocation = databaseDirectory.appendingStoreFile()
                let options = NSPersistentStoreCoordinator.persistentStoreOptions(supportsMigration: false)

                // Recreate the persistent store inside a new location
                try coordinator.replacePersistentStore(at: backupLocation, destinationOptions: options, withPersistentStoreFrom: storeFile, sourceOptions: options, ofType: NSSQLiteStoreType)
                let metadata = BackupMetadata(userIdentifier: accountIdentifier, clientIdentifier: clientIdentifier, appVersionProvider: Bundle.main, modelVersionProvider: model)
                try metadata.write(to: metadataURL)
                
                DispatchQueue.main.async {
                    completion(.success(.init(url: backupDirectory, metadata: metadata)))
                    dispatchGroup?.leave()
                }
            } catch {
                fail(.failedToWrite)
            }
        }
    }
}
