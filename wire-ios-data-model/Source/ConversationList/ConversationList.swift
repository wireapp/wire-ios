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

/// A collection of conversation instances with additional infos.
@objc(ZMConversationList) @objcMembers
public final class ConversationList: NSObject {

    public weak var managedObjectContext: NSManagedObjectContext?

    let identifier: String
    let label: Label?
    public private(set) var items: [ZMConversation]
    private let conversationKeysAffectingSorting: NSSet
    private var filteringPredicate: NSPredicate
    private let sortDescriptors: [NSSortDescriptor]

    public convenience init(
        filteringPredicate: NSPredicate,
        managedObjectContext: NSManagedObjectContext,
        description: String
    ) {
        self.init(
            filteringPredicate: filteringPredicate,
            managedObjectContext: managedObjectContext,
            description: description,
            label: nil
        )
    }

    public init(
        filteringPredicate: NSPredicate,
        managedObjectContext: NSManagedObjectContext,
        description: String,
        label: Label?
    ) {
        self.filteringPredicate = filteringPredicate
        self.managedObjectContext = managedObjectContext
        self.identifier = description
        self.label = label
        self.sortDescriptors = ZMConversation.defaultSortDescriptors()!

        self.conversationKeysAffectingSorting = Self.calculateKeysAffectingPredicateAndSort(sortDescriptors)
        
        
        self.items = Self.createItems(filteringPredicate, sortDescriptors, managedObjectContext)

        super.init()

        managedObjectContext.performAndWait {
            managedObjectContext.conversationListObserverCenter.startObservingList(self)
        }
    }

    deinit {
        if let managedObjectContext {
            managedObjectContext.performAndWait {
                managedObjectContext.conversationListObserverCenter.removeConversationList(self)
            }
        }
    }

    static func createItems(
        _ filteringPredicate: NSPredicate,
        _ sortDescriptors: [NSSortDescriptor],
        _ context: NSManagedObjectContext
    ) -> [ZMConversation] {
        let request = ZMConversation.sortedFetchRequest()
        
        // Since this is extremely likely to trigger the "participantRoles" and "connection" relationships, we make sure these gets prefetched:
        var keyPaths =  request.relationshipKeyPathsForPrefetching
        keyPaths?.append(ZMConversationParticipantRolesKey)
        keyPaths?.append("\(ZMConversationOneOnOneUserKey).connection")

        request.relationshipKeyPathsForPrefetching = keyPaths
        request.predicate = filteringPredicate
        request.sortDescriptors = sortDescriptors
        return context.fetchOrAssert(request: request) as! [ZMConversation]
    }

    private static func calculateKeysAffectingPredicateAndSort(_ sortDescriptors: [NSSortDescriptor]) -> NSSet {
        let keysAffectingSorting = NSMutableSet()
        for sd in sortDescriptors {
            if let key = sd.key {
                keysAffectingSorting.add(key)
            }
        }
        return keysAffectingSorting.adding(ZMConversationListIndicatorKey) as NSSet
    }

    @objc(recreateConversationsWithPredicate:managedContext:)
    func recreateConversations(with predicate: NSPredicate, context: NSManagedObjectContext) {
        filteringPredicate = predicate
        items = Self.createItems(predicate, sortDescriptors, context)

        context.performAndWait {
            context.conversationListObserverCenter.startObservingList(self)
        }
    }

    private func sortInsertConversation(_ conversation: ZMConversation) {
        let index = (items as NSArray).index(
            of: conversation,
            inSortedRange: NSRange(location: 0, length: items.count),
            options: .insertionIndex,
            usingComparator: comparator
        )
        items.insert(conversation, at: index)
    }

    private var comparator: Comparator {
        let sortDescriptors = sortDescriptors
        return {
            let c0 = $0 as! ZMConversation
            let c1 = $1 as! ZMConversation

            if c0.conversationListIndicator == .activeCall, c1.conversationListIndicator != .activeCall {
                return .orderedAscending
            } else if c1.conversationListIndicator == .activeCall, c0.conversationListIndicator != .activeCall {
                return .orderedDescending
            }

            for sd in sortDescriptors {
                let result = sd.compare(c0, to: c1)
                if result != .orderedSame {
                    return result
                }
            }
            return .orderedSame
        }
    }

    func object(at index: Int) -> ZMConversation? {
        guard items.indices.contains(index) else {
            assertionFailure("index out of bounds")
            return nil
        }
        return items[index]
    }

    func index(of conversation: ZMConversation) -> Int? {
        items.firstIndex(of: conversation)
    }

    func shortDescription() -> String {
        .init(
            format: "<%@: %p> %@ (predicate: %@)",
            String(describing: Self.self),
            self,
            identifier,
            filteringPredicate
        )
    }

    public override var description: String {
        shortDescription() + "\n" + super.description
    }

    public func resort() {
        let items = NSMutableArray(array: items)
        items.sort(comparator: comparator)
        self.items = items as! [ZMConversation]
    }

    // MARK: - ZMUpdates

    func predicateMatchesConversation(_ conversation: ZMConversation) -> Bool {
        filteringPredicate.evaluate(with: conversation)
    }

    func sortingIsAffected(byConversationKeys conversationKeys: Set<AnyHashable>) -> Bool {
        conversationKeysAffectingSorting.intersects(conversationKeys)
    }

    func resortConversation(_ conversation: ZMConversation) {
        if let index = items.firstIndex(of: conversation) {
            items.remove(at: index)
        }
        sortInsertConversation(conversation)
    }

    func removeConversations(_ conversations: Set<ZMConversation>) {
        items.removeAll { conversation in
            conversations.contains(conversation)
        }
    }

    func insertConversations(_ conversations: Set<ZMConversation>) {
        var conversations = conversations
        items.forEach { conversation in
            conversations.remove(conversation)
        }
        conversations.forEach { conversation in
            sortInsertConversation(conversation)
        }
    }

    // MARK: - UserSession

    public static func refetchAllLists(inUserSession session: ContextProvider) {
        session.viewContext.conversationListDirectory().refetchAllLists(in: session.viewContext)
    }

    public static func conversationsIncludingArchived(inUserSession session: ContextProvider?) -> ConversationList! {
        guard let session else { return nil }
        return session.viewContext.conversationListDirectory().conversationsIncludingArchived
    }

    public static func conversations(inUserSession session: ContextProvider?) -> ConversationList! {
        guard let session else { return nil }
        return session.viewContext.conversationListDirectory().unarchivedConversations
    }

    public static func archivedConversations(inUserSession session: ContextProvider?) -> ConversationList! {
        guard let session else { return nil }
        return session.viewContext.conversationListDirectory().archivedConversations
    }

    public static func pendingConnectionConversations(inUserSession session: ContextProvider?) -> ConversationList! {
        guard let session else { return nil }
        return session.viewContext.conversationListDirectory().pendingConnectionConversations
    }

    public static func clearedConversations(inUserSession session: ContextProvider?) -> ConversationList! {
        guard let session else { return nil }
        return session.viewContext.conversationListDirectory().clearedConversations
    }
}
