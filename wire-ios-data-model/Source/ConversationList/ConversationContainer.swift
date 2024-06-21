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
@objc(ZMConversationContainer) @objcMembers
public final class ConversationContainer: NSObject {

    var count: Int {
        backingList.count
    }

    weak var managedObjectContext: NSManagedObjectContext?

    let identifier: String
    let label: Label?
    var items: [ZMConversation] { backingList }

    private var backingList: [ZMConversation]
    private let conversationKeysAffectingSorting: NSSet
    private let filteringPredicate: NSPredicate
    private let sortDescriptors: [NSSortDescriptor]
    private let customDebugDescription: String

    private convenience init(
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

    init(
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

        conversationKeysAffectingSorting = Self.calculateKeysAffectingPredicateAndSort()
        backingList = Self.createBackingList(allConversations)

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

    private static func createBackingList(_ conversations: [ZMConversation]) -> [ZMConversation] {
        fatalError()
        /*
        NSArray *filtered = [conversations filteredArrayUsingPredicate:self.filteringPredicate];
        self.backingList = [[filtered sortedArrayUsingDescriptors:[ZMConversation defaultSortDescriptors]] mutableCopy];
         */
    }

    private static func calculateKeysAffectingPredicateAndSort() -> NSSet {
        /*

         NSMutableSet *keysAffectingSorting = [NSMutableSet set];
         for (NSSortDescriptor *sd in self.sortDescriptors) {
             NSString *key = sd.key;
             if (key != nil) {
                 [keysAffectingSorting addObject:key];
             }
         }
         _conversationKeysAffectingSorting = [[keysAffectingSorting copy] setByAddingObject:ZMConversationListIndicatorKey];

         */
        fatalError()
    }

    func recreate(
        allConversations: [ZMConversation],
        predicate: NSPredicate
    ) {
        fatalError()

        /*
        self.filteringPredicate = predicate;
        [self createBackingList:conversations];

        [self.moc performBlockAndWait:^{
            [self.moc.conversationListObserverCenter startObservingList:self];
        }];
         */
    }

    private func sortInsertConversation(_ conversation: ZMConversation) {
        fatalError()
        /*
         NSUInteger const idx = [self.backingList indexOfObject:conversation
                                                  inSortedRange:NSMakeRange(0, self.backingList.count)
                                                        options:NSBinarySearchingInsertionIndex
                                                usingComparator:self.comparator];
         [self.backingList insertObject:conversation atIndex:idx];
         */
    }

    private var comparator: Comparator {
        fatalError()

        /*
         return ^NSComparisonResult(ZMConversation *c1, ZMConversation* c2){
             if(c1.conversationListIndicator == ZMConversationListIndicatorActiveCall && c2.conversationListIndicator != ZMConversationListIndicatorActiveCall) {
                 return NSOrderedAscending;
             } else if(c2.conversationListIndicator == ZMConversationListIndicatorActiveCall && c1.conversationListIndicator != ZMConversationListIndicatorActiveCall) {
                 return NSOrderedDescending;
             }

             for (NSSortDescriptor *sd in self.sortDescriptors) {
                 NSComparisonResult const r = [sd compareObject:c1 toObject:c2];
                 if (r != NSOrderedSame) {
                     return r;
                 }
             }
             return NSOrderedSame;
         };
         */
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
        fatalError()
        /*
         [self.backingList sortUsingComparator:self.comparator];
         */
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

    /*

     + (void)refetchAllListsInUserSession:(id<ContextProvider>)session;
     {
         [session.viewContext.conversationListDirectory refetchAllListsInManagedObjectContext:session.viewContext];
     }

     + (ZMConversationContainer *)conversationsIncludingArchivedInUserSession:(id<ContextProvider>)session
     {
         VerifyReturnNil(session != nil);
         return session.viewContext.conversationListDirectory.conversationsIncludingArchived;
     }

     + (ZMConversationContainer *)conversationsInUserSession:(id<ContextProvider>)session
     {
         VerifyReturnNil(session != nil);
         return session.viewContext.conversationListDirectory.unarchivedConversations;
     }

     + (ZMConversationContainer *)archivedConversationsInUserSession:(id<ContextProvider>)session
     {
         VerifyReturnNil(session != nil);
         return session.viewContext.conversationListDirectory.archivedConversations;
     }

     + (ZMConversationContainer *)pendingConnectionConversationsInUserSession:(id<ContextProvider>)session
     {
         VerifyReturnNil(session != nil);
         return session.viewContext.conversationListDirectory.pendingConnectionConversations;
     }

     + (ZMConversationContainer *)clearedConversationsInUserSession:(id<ContextProvider>)session
     {
         VerifyReturnNil(session != nil);
         return session.viewContext.conversationListDirectory.clearedConversations;
     }

     */
}
