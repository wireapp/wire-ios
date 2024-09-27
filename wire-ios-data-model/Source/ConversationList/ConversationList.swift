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

import CoreData

/// A collection of conversation instances with additional infos.
@objc(ZMConversationList) @objcMembers
public final class ConversationList: NSObject {
    // MARK: Lifecycle

    public convenience init(
        allConversations: [ZMConversation],
        filteringPredicate: NSPredicate,
        managedObjectContext: NSManagedObjectContext,
        description: String
    ) {
        self.init(
            allConversations: allConversations,
            filteringPredicate: filteringPredicate,
            managedObjectContext: managedObjectContext,
            description: description,
            label: nil
        )
    }

    public init(
        allConversations: [ZMConversation],
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
        self.items = Self.createItems(allConversations, filteringPredicate, sortDescriptors)

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

    // MARK: Public

    public weak var managedObjectContext: NSManagedObjectContext?

    public private(set) var items: [ZMConversation]

    override public var description: String {
        shortDescription() + "\n" + super.description
    }

    // MARK: - UserSession

    public static func refetchAllLists(inUserSession session: ContextProvider) {
        session.viewContext.conversationListDirectory().refetchAllLists(in: session.viewContext)
    }

    public static func conversationsIncludingArchived(inUserSession session: ContextProvider?) -> ConversationList! {
        guard let session else {
            return nil
        }
        return session.viewContext.conversationListDirectory().conversationsIncludingArchived
    }

    public static func conversations(inUserSession session: ContextProvider?) -> ConversationList! {
        guard let session else {
            return nil
        }
        return session.viewContext.conversationListDirectory().unarchivedConversations
    }

    public static func archivedConversations(inUserSession session: ContextProvider?) -> ConversationList! {
        guard let session else {
            return nil
        }
        return session.viewContext.conversationListDirectory().archivedConversations
    }

    public static func pendingConnectionConversations(inUserSession session: ContextProvider?) -> ConversationList! {
        guard let session else {
            return nil
        }
        return session.viewContext.conversationListDirectory().pendingConnectionConversations
    }

    public static func clearedConversations(inUserSession session: ContextProvider?) -> ConversationList! {
        guard let session else {
            return nil
        }
        return session.viewContext.conversationListDirectory().clearedConversations
    }

    public func resort() {
        let items = NSMutableArray(array: items)
        items.sort(comparator: comparator)
        self.items = items as! [ZMConversation]
    }

    // MARK: Internal

    let identifier: String
    let label: Label?

    func recreate(
        allConversations: [ZMConversation],
        predicate: NSPredicate
    ) {
        filteringPredicate = predicate
        items = Self.createItems(allConversations, predicate, sortDescriptors)

        let managedObjectContext = managedObjectContext
        managedObjectContext?.performAndWait {
            managedObjectContext?.conversationListObserverCenter.startObservingList(self)
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
        for conversation in items {
            conversations.remove(conversation)
        }
        for conversation in conversations {
            sortInsertConversation(conversation)
        }
    }

    // MARK: Private

    private let conversationKeysAffectingSorting: NSSet
    private var filteringPredicate: NSPredicate
    private let sortDescriptors: [NSSortDescriptor]

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

    private static func createItems(
        _ conversations: [ZMConversation],
        _ filteringPredicate: NSPredicate,
        _ sortDescriptors: [NSSortDescriptor]
    ) -> [ZMConversation] {
        let filtered = (conversations as NSArray).filtered(using: filteringPredicate)
        return NSSet(array: filtered).sortedArray(using: sortDescriptors) as! [ZMConversation]
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

    private func sortInsertConversation(_ conversation: ZMConversation) {
        let index = (items as NSArray).index(
            of: conversation,
            inSortedRange: NSRange(location: 0, length: items.count),
            options: .insertionIndex,
            usingComparator: comparator
        )
        items.insert(conversation, at: index)
    }
}
