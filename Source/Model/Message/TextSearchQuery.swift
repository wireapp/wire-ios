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
import ZMUtilities


extension ZMMessage {

    func updateNormalizedText() {
        // no-op
    }

}

extension ZMClientMessage {

    override func updateNormalizedText() {
        if let normalized = textMessageData?.messageText?.normalizedForSearch() as? String {
            normalizedText = normalized
        } else {
            normalizedText = ""
        }
    }

}

extension ZMClientMessage {

    static func predicateForMessagesMatching(_ queryComponents: [String]) -> NSPredicate {
        let predicates = queryComponents.map { NSPredicate(format: "%K CONTAINS[n] %@", #keyPath(ZMMessage.normalizedText), $0) }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    static func predicateForMessages(inConversationWith identifier: UUID) -> NSPredicate {
        return NSPredicate(
            format: "%K.%K == %@",
            ZMMessageConversationKey,
            ZMConversationRemoteIdentifierDataKey,
            (identifier as NSUUID).data() as NSData
        )
    }

    static func predicateForNotIndexedMessages() -> NSPredicate {
        return NSPredicate(format: "%K == NULL", #keyPath(ZMMessage.normalizedText))
    }

    static func predicateForIndexedMessages() -> NSPredicate {
        return NSPredicate(format: "%K != NULL", #keyPath(ZMMessage.normalizedText))
    }

    static func descendingFetchRequest(with predicate: NSPredicate) -> NSFetchRequest<NSFetchRequestResult>? {
        let request = sortedFetchRequest(with: predicate)
        request?.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        return request
    }

}


public class TextQueryResult: NSObject {
    public var matches: [ZMMessage]
    public var hasMore: Bool
    public weak var query: TextSearchQuery?

    init(query: TextSearchQuery?, matches: [ZMMessage], hasMore: Bool) {
        self.query = query
        self.matches = matches
        self.hasMore = hasMore
    }

    func updated(appending matches: [ZMMessage], hasMore: Bool) -> TextQueryResult {
        return TextQueryResult(query: self.query, matches: self.matches + matches, hasMore: hasMore)
    }
}


public struct TextSearchQueryFetchConfiguration {
    let notIndexedBatchSize: Int
    let indexedBatchSize: Int
}


public protocol TextSearchQueryDelegate: class {
    func textSearchQueryDidReceive(result: TextQueryResult)
}


/// This class should be used to perform a text search for messages in a conversation.
/// Each instance can only be used to perform a search once. A running instance can be cancelled.
public class TextSearchQuery: NSObject {

    private let uiMOC: NSManagedObjectContext
    private let syncMOC: NSManagedObjectContext

    private let conversationRemoteIdentifier: UUID
    private let conversation: ZMConversation
    private let queryStrings: [String]

    /// The fetch configuration specifies the fetch requests batch sizes
    private let fetchConfiguration: TextSearchQueryFetchConfiguration

    private weak var delegate: TextSearchQueryDelegate?

    /// Whether the query has been cancelled (if `cancelled` has been called).
    private var cancelled = false

    /// Whether the query has alreday been executed (if `execute` has already been called).
    private var executed = false

    private var result: TextQueryResult?
    private var numberOfIndexedMessages = 0
    private var numberOfNonIndexedMessages = 0

    /// Creates a new `TextSearchQuery` object.
    /// - param conversation The conversation in which the search should be performed. Needs to belong to the UI context.
    /// - param query The query string which will be searched for in the messages of the conversation.
    /// - param delegate The delegate which will be notified with the results.
    /// - param configuration An optional configuration specifying the fetch batch size (useful in tests).
    public init?(
        conversation: ZMConversation,
        query: String,
        delegate: TextSearchQueryDelegate,
        configuration: TextSearchQueryFetchConfiguration = .init(notIndexedBatchSize: 200, indexedBatchSize: 200)
        ) {

        guard query.characters.count > 1 else { return nil }
        guard let uiMOC = conversation.managedObjectContext, let syncMOC = uiMOC.zm_sync else {
            fatal("NSManagedObjectContexts not accessible.")
        }

        guard uiMOC.zm_isUserInterfaceContext else {
            fatal("`init` called with a non UI MOC conversation.")
        }

        self.uiMOC = uiMOC
        self.syncMOC = syncMOC
        self.conversation = conversation
        self.conversationRemoteIdentifier = conversation.remoteIdentifier!
        self.queryStrings = query.normalizedForSearch().components(separatedBy: .whitespacesAndNewlines).filter { $0.characters.count > 1 }
        self.delegate = delegate
        self.fetchConfiguration = configuration
    }

    /// Start the search, the delegate will be called with
    /// results one or more times if not cancelled.
    public func execute() {
        precondition(!executed, "Trying to re-execute an already executed query. Each query can only be executed once.")
        executed = true

        if queryStrings.isEmpty {
            return notifyDelegate(with: [], hasMore: false)
        }

        syncMOC.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }

            // We store the count of indexed and non-indexed messages in the conversation.
            // This will be used to ensure we only call the delegate with `hasMore = false` once.
            self.numberOfIndexedMessages = self.countForIndexedMessages()
            self.numberOfNonIndexedMessages = self.countForNonIndexedMessages()

            self.executeQueryForIndexedMessages { [weak self] in
                self?.executeQueryForNonIndexedMessages()
            }
        }
    }

    /// Cancel the current search query.
    /// A new `TextSearchQuery` object has to be created to start a new search.
    public func cancel() {
        cancelled = true
    }

    /// Fetches the next batch of indexed messages in a conversation and notifies
    /// the delegate about the result.
    /// - param callCount The number of times this method has been called recursivly, used the compute the `fetchOffset`
    /// - param completion The completion handler which will be called after all indexed messages have been queried
    private func executeQueryForIndexedMessages(callCount: Int = 0, completion: @escaping () -> Void) {
        guard !cancelled else { return }
        guard numberOfIndexedMessages > 0 else { return completion() }

        let queryPredicateForIndexedMessages = ZMClientMessage.predicateForIndexedMessages() && predicateForQueryMatch

        syncMOC.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }

            let request = ZMClientMessage.descendingFetchRequest(with: queryPredicateForIndexedMessages)
            request?.fetchLimit = self.fetchConfiguration.indexedBatchSize
            request?.fetchOffset = callCount * self.fetchConfiguration.indexedBatchSize

            guard let matches = self.syncMOC.executeFetchRequestOrAssert(request) as? [ZMClientMessage] else { return completion() }

            // Notify the delegate
            let nextOffset = (callCount + 1) * self.fetchConfiguration.indexedBatchSize
            let needsMoreFetches = nextOffset < self.numberOfIndexedMessages
            self.notifyDelegate(with: matches, hasMore: needsMoreFetches || self.numberOfNonIndexedMessages > 0)

            if needsMoreFetches {
                self.executeQueryForIndexedMessages(callCount: callCount + 1, completion: completion)
            } else {
                completion()
            }
        }
    }

    /// Fetches the next batch of not indexed messages in a conversation and updates
    /// their `noralizedText` property. After the indexing the indexed messages
    /// are queried for the search term and the delegate is notified.
    private func executeQueryForNonIndexedMessages() {
        guard !cancelled && numberOfNonIndexedMessages > 0 else { return }

        syncMOC.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }

            let request = ZMClientMessage.descendingFetchRequest(with: self.predicateForNotIndexedMessages)
            request?.fetchLimit = self.fetchConfiguration.notIndexedBatchSize

            guard let messagesToIndex = self.syncMOC.executeFetchRequestOrAssert(request) as? [ZMClientMessage] else { return }
            messagesToIndex.forEach {
                // We populate the `normalizedText` field, so the search can be 
                // performed faster on the normalized field the next time.
                $0.updateNormalizedText()
            }
            self.syncMOC.saveOrRollback()

            let matches = (messagesToIndex as NSArray).filtered(using: self.predicateForQueryMatch)
            let hasMore = messagesToIndex.count == self.fetchConfiguration.notIndexedBatchSize

            // Notify the delegate
            self.notifyDelegate(with: matches as! [ZMMessage], hasMore: hasMore)

            if hasMore {
                self.executeQueryForNonIndexedMessages()
            }
        }
    }

    /// Fetches the objects on the UI context and notifies the delegate
    private func notifyDelegate(with messages: [ZMMessage], hasMore: Bool) {
        let objectIDs = messages.map { $0.objectID }
        uiMOC.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }
            let uiMessages = objectIDs.flatMap {
                (try? self.uiMOC.existingObject(with: $0)) as? ZMMessage
            }

            let queryResult = self.result?.updated(appending: uiMessages, hasMore: hasMore)
                           ?? TextQueryResult(query: self, matches: uiMessages, hasMore: hasMore)

            self.result = queryResult
            self.delegate?.textSearchQueryDidReceive(result: queryResult)
        }
    }

    /// Returns the count of indexed messages in the conversation. 
    /// Needs to be called from the syncMOC's Queue.
    private func countForIndexedMessages() -> Int {
        guard let request = ZMClientMessage.sortedFetchRequest(with: predicateForIndexedMessages) else { return 0 }
        return (try? self.syncMOC.count(for: request)) ?? 0
    }

    /// Returns the count of not indexed indexed messages in the conversation. 
    /// Needs to be called from the syncMOC's Queue.
    private func countForNonIndexedMessages() -> Int {
        guard let request = ZMMessage.sortedFetchRequest(with: predicateForNotIndexedMessages) else { return 0 }
        return (try? self.syncMOC.count(for: request)) ?? 0
    }

    /// Predicate matching messages containing the query in the conversation
    private lazy var predicateForQueryMatch: NSPredicate = {
        return ZMClientMessage.predicateForMessagesMatching(self.queryStrings)
            && ZMClientMessage.predicateForMessages(inConversationWith: self.conversationRemoteIdentifier)
    }()

    /// Predicate matching messages without a populated `normalizedText` field in the conversation
    private lazy var predicateForNotIndexedMessages: NSPredicate = {
        return ZMClientMessage.predicateForNotIndexedMessages()
            && ZMClientMessage.predicateForMessages(inConversationWith: self.conversationRemoteIdentifier)
    }()

    /// Predicate matching messages with a populated `normalizedText` field in the conversation
    private lazy var predicateForIndexedMessages: NSPredicate = {
        return ZMClientMessage.predicateForIndexedMessages()
            && ZMClientMessage.predicateForMessages(inConversationWith: self.conversationRemoteIdentifier)
    }()

}

