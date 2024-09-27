//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireDataModel

@objc
public final class ConversationStatusStrategy: ZMObjectSyncStrategy, ZMContextChangeTracker {
    // MARK: Public

    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        var didUpdateConversation = false

        for object in objects {
            if let conv = object as? ZMConversation {
                if conv.hasLocalModifications(forKey: lastReadKey) {
                    do {
                        try ZMConversation.updateSelfConversation(withLastReadOf: conv)
                        let lastReadKeySet: Set<AnyHashable> = [lastReadKey]
                        conv.resetLocallyModifiedKeys(lastReadKeySet)
                        didUpdateConversation = true
                    } catch {
                        Logging.messageProcessing
                            .warn(
                                "Failed to update last read in self conversation. Reason: \(error.localizedDescription)"
                            )
                        continue
                    }
                }
                if conv.hasLocalModifications(forKey: clearedKey) {
                    do {
                        try ZMConversation.updateSelfConversation(withClearedOf: conv)
                        let clearedKeySet: Set<AnyHashable> = [clearedKey]
                        conv.resetLocallyModifiedKeys(clearedKeySet)
                        conv.deleteOlderMessages()
                        didUpdateConversation = true
                    } catch {
                        Logging.messageProcessing
                            .warn(
                                "Failed to update cleared in self conversation. Reason: \(error.localizedDescription)"
                            )
                        continue
                    }
                }
            }
        }

        if didUpdateConversation {
            managedObjectContext?.enqueueDelayedSave()
        }
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ZMConversation.entityName())
        return request
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        objectsDidChange(objects)
    }

    // MARK: Internal

    let lastReadKey = "lastReadServerTimeStamp"
    let clearedKey = "clearedTimeStamp"
}
