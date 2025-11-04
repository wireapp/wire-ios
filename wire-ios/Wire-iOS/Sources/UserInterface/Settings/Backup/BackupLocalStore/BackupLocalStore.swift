//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import CoreData
import WireBackup
import WireDataModel
import WireDomain

struct BackupLocalStore: BackupLocalStoreProtocol, @unchecked Sendable {

    /// The context to call `perform(schedule:_:)` on if needed.
    let backupContext: NSManagedObjectContext
    let contextProvider: ContextProvider
    let assetTransferStateResolver: AssetTransferStateResolverProtocol
    var clientMessageEntityDescription: NSEntityDescription?
    var assetMessageEntityDescription: NSEntityDescription?

    init(
        contextProvider: ContextProvider,
        assetTransferStateResolver: AssetTransferStateResolverProtocol = AssetTransferStateResolver()
    ) {
        self.contextProvider = contextProvider
        self.assetTransferStateResolver = assetTransferStateResolver
        self.backupContext = contextProvider.newBackgroundContext()

        setupBackupContext()

        self.clientMessageEntityDescription = NSEntityDescription.entity(
            forEntityName: ZMClientMessage.entityName(),
            in: backupContext
        )
        self.assetMessageEntityDescription = NSEntityDescription.entity(
            forEntityName: ZMAssetClientMessage.entityName(),
            in: backupContext
        )
    }

    private func setupBackupContext() {

        // Ensures imported data overwrites existing values without validation conflicts.
        backupContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Prevents automatic UI context merges that could slow down the import.
        backupContext.automaticallyMergesChangesFromParent = false

        // Turns off undo manager (Core Data otherwise tracks diffs, which is expensive).
        backupContext.undoManager = nil
    }

    func countModels() async throws -> (userCount: Int, conversationCount: Int, messageCount: Int) {
        try await backupContext.perform { [backupContext] in
            let userCount = try backupContext.count(for: ZMUser.fetchRequest())
            let conversationCount = try backupContext.count(for: ZMConversation.fetchRequest())
            let messageCount = try backupContext.count(for: ZMMessage.fetchRequest())
            return (userCount, conversationCount, messageCount)
        }
    }

}
