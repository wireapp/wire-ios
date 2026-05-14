//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public struct LegacyAccountStorageInventory: Equatable {

    public struct Item: Equatable {

        public enum Kind: Equatable {
            case file
            case directory
        }

        public let kind: Kind
        public let url: URL
        public let exists: Bool

        public init(kind: Kind, url: URL, exists: Bool) {
            self.kind = kind
            self.url = url
            self.exists = exists
        }

    }

    public struct ChecklistItem: Equatable {

        public let name: String
        public let item: Item
        public let isRequired: Bool

        public init(name: String, item: Item, isRequired: Bool) {
            self.name = name
            self.item = item
            self.isRequired = isRequired
        }

    }

    public let accountDirectory: URL
    public let messageStore: Item
    public let messageStoreWAL: Item
    public let messageStoreSHM: Item
    public let eventStore: Item
    public let coreCryptoDirectory: Item

    public var checklist: [ChecklistItem] {
        [
            ChecklistItem(name: "message store", item: messageStore, isRequired: true),
            ChecklistItem(name: "message store WAL", item: messageStoreWAL, isRequired: false),
            ChecklistItem(name: "message store SHM", item: messageStoreSHM, isRequired: false),
            ChecklistItem(name: "event store", item: eventStore, isRequired: true),
            ChecklistItem(name: "core crypto directory", item: coreCryptoDirectory, isRequired: true)
        ]
    }

    public var missingRequiredItems: [ChecklistItem] {
        checklist.filter { $0.isRequired && !$0.item.exists }
    }

    public var hasRequiredItems: Bool {
        missingRequiredItems.isEmpty
    }

    public init(accountDirectory: URL, fileManager: FileManager = .default) {
        let storeURL = accountDirectory
            .appendingPathComponent("store")
            .appendingPathComponent("store.wiredatabase")
        let eventStoreURL = accountDirectory
            .appendingPathComponent("events")
            .appendingPathComponent("ZMEventModel.sqlite")
        let coreCryptoDirectoryURL = accountDirectory.appendingPathComponent("corecrypto")
        let storeWALURL = storeURL.appendingSidecarSuffix("-wal")
        let storeSHMURL = storeURL.appendingSidecarSuffix("-shm")

        self.accountDirectory = accountDirectory
        self.messageStore = Item(kind: .file, url: storeURL, exists: fileManager.fileExists(at: storeURL, kind: .file))
        self.messageStoreWAL = Item(
            kind: .file,
            url: storeWALURL,
            exists: fileManager.fileExists(at: storeWALURL, kind: .file)
        )
        self.messageStoreSHM = Item(
            kind: .file,
            url: storeSHMURL,
            exists: fileManager.fileExists(at: storeSHMURL, kind: .file)
        )
        self.eventStore = Item(
            kind: .file,
            url: eventStoreURL,
            exists: fileManager.fileExists(at: eventStoreURL, kind: .file)
        )
        self.coreCryptoDirectory = Item(
            kind: .directory,
            url: coreCryptoDirectoryURL,
            exists: fileManager.fileExists(at: coreCryptoDirectoryURL, kind: .directory)
        )
    }

}

private extension URL {

    func appendingSidecarSuffix(_ suffix: String) -> URL {
        deletingLastPathComponent().appendingPathComponent(lastPathComponent + suffix)
    }

}

private extension FileManager {

    func fileExists(at url: URL, kind: LegacyAccountStorageInventory.Item.Kind) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileExists(atPath: url.path, isDirectory: &isDirectory)

        switch kind {
        case .file:
            return exists && !isDirectory.boolValue
        case .directory:
            return exists && isDirectory.boolValue
        }
    }

}
