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

// MARK: - TopConversationsDirectory

/// Directory of various conversation lists
/// This object is expected to be used on the UI context only
@objcMembers
public class TopConversationsDirectory: NSObject {
    fileprivate let uiMOC: NSManagedObjectContext
    fileprivate let syncMOC: NSManagedObjectContext
    fileprivate static let topConversationSize = 25

    /// Cached top conversations
    /// - warning: Might include deleted or blocked conversations
    fileprivate var topConversationsCache: [ZMConversation] = []

    public init(managedObjectContext: NSManagedObjectContext) {
        self.uiMOC = managedObjectContext
        self.syncMOC = managedObjectContext.zm_sync
        super.init()
        loadList()
    }
}

// MARK: - Top conversation

private let topConversationsObjectIDKey = "WireTopConversationsObjectIDKey"

@objc
extension TopConversationsDirectory {
    public func refreshTopConversations() {
        syncMOC.performGroupedBlock {
            let conversations = self.fetchOneOnOneConversations()
            let countByConversation: [ZMConversation: Int] = conversations
                .reduce(into: .init()) { partialResult, item in
                    partialResult[item] = item.lastMonthMessageCount()
                }
            let identifiers = countByConversation
                .filter { _, value in value > 0 }
                .sorted { $0.1 > $1.1 }
                .prefix(TopConversationsDirectory.topConversationSize)
                .map(\.0.objectID)
            self.updateUIList(with: identifiers)
        }
    }

    private func updateUIList(with identifiers: [NSManagedObjectID]) {
        uiMOC.performGroupedBlock {
            self.topConversationsCache = identifiers.compactMap {
                (try? self.uiMOC.existingObject(with: $0)) as? ZMConversation
            }
            self.persistList()
        }
    }

    private func fetchOneOnOneConversations() -> [ZMConversation] {
        let request = ZMConversation.sortedFetchRequest(with: ZMConversation.predicateForActiveOneOnOneConversations)

        return syncMOC.fetchOrAssert(request: request) as! [ZMConversation]
    }

    /// Top conversations
    public var topConversations: [ZMConversation] {
        topConversationsCache.filter { !$0.isZombieObject && $0.oneOnOneUser?.connection?.status == .accepted }
    }

    /// Persist list of conversations to persistent store
    private func persistList() {
        let valueToSave = topConversations.map { $0.objectID.uriRepresentation().absoluteString }
        uiMOC.setPersistentStoreMetadata(array: valueToSave, key: topConversationsObjectIDKey)
        TopConversationsDirectoryNotification().post(in: uiMOC.notificationContext)
    }

    /// Load list from persistent store
    private func loadList() {
        guard let ids = uiMOC.persistentStoreMetadata(forKey: topConversationsObjectIDKey) as? [String] else {
            return
        }
        let managedObjectIDs = ids.compactMap(URL.init)
            .compactMap { self.uiMOC.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: $0) }
        topConversationsCache = managedObjectIDs.compactMap { self.uiMOC.object(with: $0) as? ZMConversation }
    }
}

// MARK: - TopConversationsDirectoryObserver

@objc
public protocol TopConversationsDirectoryObserver {
    @objc
    func topConversationsDidChange()
}

// MARK: - TopConversationsDirectoryNotification

struct TopConversationsDirectoryNotification: SelfPostingNotification {
    static let notificationName = NSNotification.Name(rawValue: "TopConversationsDirectoryNotification")
}

extension TopConversationsDirectory {
    @objc(addObserver:)
    public func add(observer: TopConversationsDirectoryObserver) -> Any {
        NotificationInContext.addObserver(
            name: TopConversationsDirectoryNotification.notificationName,
            context: uiMOC.notificationContext
        ) { [weak observer] _ in
            observer?.topConversationsDidChange()
        }
    }
}

extension ZMConversation {
    fileprivate static var predicateForActiveOneOnOneConversations: NSPredicate {
        let oneOnOnePredicate = NSPredicate(
            format: "%K == %d",
            #keyPath(ZMConversation.conversationType),
            ZMConversationType.oneOnOne.rawValue
        )
        let acceptedPredicate = NSPredicate(
            format: "%K == %d",
            #keyPath(ZMConversation.oneOnOneUser.connection.status),
            ZMConnectionStatus.accepted.rawValue
        )
        return NSCompoundPredicate(andPredicateWithSubpredicates: [oneOnOnePredicate, acceptedPredicate])
    }

    fileprivate func lastMonthMessageCount() -> Int {
        guard let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else { return 0 }

        var count = 0
        for message in lastMessages() {
            guard let timestamp = message.serverTimestamp else { continue }
            guard message.systemMessageData == nil else { continue }
            guard timestamp >= oneMonthAgo else { return count }
            count += 1
        }

        return count
    }
}
