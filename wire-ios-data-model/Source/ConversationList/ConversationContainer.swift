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

    var count: Int {
        backingList.count
    }

    public weak var managedObjectContext: NSManagedObjectContext?

    let identifier: String
    let label: Label?
    public var items: [ZMConversation] { backingList }

    private var backingList: [ZMConversation]
    private let conversationKeysAffectingSorting: NSSet
    private var filteringPredicate: NSPredicate
    private let sortDescriptors: [NSSortDescriptor]
    private let customDebugDescription: String

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
        identifier = description
        customDebugDescription = identifier
        self.label = label
        sortDescriptors = ZMConversation.defaultSortDescriptors()!

        conversationKeysAffectingSorting = Self.calculateKeysAffectingPredicateAndSort(sortDescriptors)
        backingList = Self.createBackingList(allConversations, filteringPredicate: filteringPredicate)

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

    private static func createBackingList(_ conversations: [ZMConversation], filteringPredicate: NSPredicate) -> [ZMConversation] {
        let filtered = (conversations as NSArray).filtered(using: filteringPredicate)
        return NSSet(array: filtered).sortedArray(using: ZMConversation.defaultSortDescriptors()!) as! [ZMConversation]
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

    func recreate(
        allConversations: [ZMConversation],
        predicate: NSPredicate
    ) {
        filteringPredicate = predicate
        backingList = Self.createBackingList(backingList, filteringPredicate: predicate)

        let managedObjectContext = managedObjectContext
        managedObjectContext?.performAndWait {
            managedObjectContext?.conversationListObserverCenter.startObservingList(self)
        }
    }

    private func sortInsertConversation(_ conversation: ZMConversation) {
        let index = (backingList as NSArray).index(of: conversation, inSortedRange: NSRange(location: 0, length: backingList.count), options: .insertionIndex, usingComparator: comparator)
        backingList.insert(conversation, at: index)
    }

    private var comparator: Comparator {
        let sortDescriptors = sortDescriptors
        return {
            let c0 = $0 as! ZMConversation
            let c1 = $1 as! ZMConversation

            if c0.conversationListIndicator == .activeCall && c1.conversationListIndicator != .activeCall {
                return .orderedAscending
            } else if c1.conversationListIndicator == .activeCall && c0.conversationListIndicator != .activeCall {
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
        guard backingList.indices.contains(index) else {
            assertionFailure("index out of bounds")
            return nil
        }
        return backingList[index]
    }

    func index(of conversation: ZMConversation) -> Int? {
        backingList.firstIndex(of: conversation)
    }

    func shortDescription() -> String {
        .init(
            format: "<%@: %p> %@ (predicate: %@)",
            String(describing: Self.self),
            self,
            customDebugDescription,
            filteringPredicate
        )
    }

    public override var description: String {
        shortDescription() + "\n" + super.description
    }

    func resort() {
        let backingList = NSMutableArray(array: backingList)
        backingList.sort(comparator: comparator)
        self.backingList = backingList as! [ZMConversation]
    }

    // MARK: - ZMUpdates

    func predicateMatchesConversation(_ conversation: ZMConversation) -> Bool {
        filteringPredicate.evaluate(with: conversation)
    }

    func sortingIsAffected(byConversationKeys conversationKeys: Set<AnyHashable>) -> Bool {
        conversationKeysAffectingSorting.intersects(conversationKeys)
    }

    func resortConversation(_ conversation: ZMConversation) {
        if let index = backingList.firstIndex(of: conversation) {
            backingList.remove(at: index)
        }
        sortInsertConversation(conversation)
    }

    func removeConversations(_ conversations: Set<ZMConversation>) {
        backingList.removeAll { conversation in
            conversations.contains(conversation)
        }
    }

    func insertConversations(_ conversations: Set<ZMConversation>) {
        var conversations = conversations
        backingList.forEach { conversation in
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

    public static func conversationsIncludingArchived(inUserSession session: ContextProvider?) -> ConversationList? {
        guard let session else { return nil }
        return session.viewContext.conversationListDirectory().conversationsIncludingArchived
    }

    public static func conversations(inUserSession session: ContextProvider?) -> ConversationList? {
        guard let session else { return nil }
        return session.viewContext.conversationListDirectory().unarchivedConversations
    }

    public static func archivedConversations(inUserSession session: ContextProvider?) -> ConversationList? {
        guard let session else { return nil }
        return session.viewContext.conversationListDirectory().archivedConversations
    }

    public static func pendingConnectionConversations(inUserSession session: ContextProvider?) -> ConversationList? {
        guard let session else { return nil }
        return session.viewContext.conversationListDirectory().pendingConnectionConversations
    }

    public static func clearedConversations(inUserSession session: ContextProvider?) -> ConversationList? {
        guard let session else { return nil }
        return session.viewContext.conversationListDirectory().clearedConversations
    }
}
