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

// MARK: - CategoryMatch

public struct CategoryMatch: Hashable {
    // MARK: Lifecycle

    public init(including: MessageCategory, excluding: MessageCategory) {
        self.including = including
        self.excluding = excluding
    }

    // MARK: Public

    public let including: MessageCategory
    public let excluding: MessageCategory
}

public func == (lhs: CategoryMatch, rhs: CategoryMatch) -> Bool {
    (lhs.excluding == rhs.excluding) && (lhs.including == rhs.including)
}

// MARK: - AssetCollectionBatched

/// This class fetches messages and groups them by `MessageCategory` (e.g. files, images, videos etc.)
/// It first fetches all objects that have previously categorized and then performs one fetch request with
/// fetchBatchSize set. CoreData returns an array  proxy to us that is populated with objects as we iterate through the
/// array. Core Data will get rid of objects again, as they’re no longer accessed.
/// For every categorized batch it will call the delegate with the newly categorized objects and then once again when it
/// finished categorizing all objects
public class AssetCollectionBatched: NSObject, ZMCollection {
    // MARK: Lifecycle

    /// Returns a collection that automatically fetches the assets in batches
    /// @param matchingCategories: The AssetCollection only returns and calls the delegate for these categories
    public init(
        conversation: ConversationLike,
        matchingCategories: [CategoryMatch],
        delegate: AssetCollectionDelegate
    ) {
        self.conversation = conversation as? ZMConversation
        self.delegate = delegate
        self.matchingCategories = matchingCategories
        super.init()

        guard let syncMOC else {
            fatal("syncMOC not accessible")
        }
        syncMOC.performGroupedBlock { [weak self] in
            guard let self, !self.tornDown else {
                return
            }
            guard let conversation = self.conversation,
                  let syncConversation = (try? syncMOC.existingObject(with: conversation.objectID)) as? ZMConversation
            else {
                return
            }
            let allAssetMessages: [ZMAssetClientMessage] = unCategorizedMessages(for: syncConversation)
            let allClientMessages: [ZMClientMessage] = unCategorizedMessages(for: syncConversation)

            let categorizedMessages: [ZMMessage] = AssetCollectionBatched.categorizedMessages(
                for: syncConversation,
                matchPairs: self
                    .matchingCategories
            )
            if !categorizedMessages.isEmpty {
                let categorized = AssetCollectionBatched.messageMap(
                    messages: categorizedMessages,
                    matchingCategories: self.matchingCategories
                )
                notifyDelegate(newAssets: categorized, type: nil, didReachLastMessage: false)
            }

            categorizeNextBatch(type: .asset, allMessages: allAssetMessages, managedObjectContext: syncMOC)
            categorizeNextBatch(type: .client, allMessages: allClientMessages, managedObjectContext: syncMOC)
        }
    }

    deinit {
        precondition(tornDown, "Call tearDown to avoid continued fetch requests")
    }

    // MARK: Public

    public static let defaultFetchCount = 200

    /// Returns true when there are no assets to fetch OR when all assets have been processed OR the collection has been
    /// tornDown
    public var fetchingDone: Bool {
        tornDown || (assetMessagesDone && clientMessagesDone)
    }

    /// Cancels further fetch requests
    public func tearDown() {
        tornDown = true
    }

    /// Returns all assets that have been fetched thus far
    public func assets(for category: CategoryMatch) -> [ZMConversationMessage] {
        // Remove zombie objects and return remaining
        if let values = assets?[category] {
            let withoutZombie = values.filter { !$0.isZombieObject }
            assets?[category] = withoutZombie
            return withoutZombie
        }
        return []
    }

    // MARK: Internal

    enum MessagesToFetch {
        case client
        case asset
    }

    static func categorizedMessages<T: ZMMessage>(
        for conversation: ZMConversation,
        matchPairs: [CategoryMatch]
    ) -> [T] {
        precondition(
            conversation.managedObjectContext!.zm_isSyncContext,
            "Fetch should only be performed on the sync context"
        )
        let request = T.fetchRequestMatching(matchPairs: matchPairs, conversation: conversation)
        let excludedCategoryPredicate = NSPredicate(
            format: "%K & %d == 0",
            ZMMessageCachedCategoryKey,
            MessageCategory.excludedFromCollection.rawValue
        )
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            request.predicate!,
            excludedCategoryPredicate,
        ])
        request.sortDescriptors = [NSSortDescriptor(key: "serverTimestamp", ascending: false)]

        guard let result = conversation.managedObjectContext?.fetchOrAssert(request: request as! NSFetchRequest<T>)
        else {
            return []
        }
        return result
    }

    static func fetchRequestForUnCategorizedMessages<T: ZMMessage>(in conversation: ZMConversation)
        -> NSFetchRequest<T> {
        let request = NSFetchRequest<T>(entityName: T.entityName())
        request.predicate = NSPredicate(
            format: "visibleInConversation == %@ && (%K == NULL || %K == %d)",
            conversation,
            ZMMessageCachedCategoryKey,
            ZMMessageCachedCategoryKey,
            MessageCategory.none.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(key: "serverTimestamp", ascending: false)]
        request.relationshipKeyPathsForPrefetching = ["dataSet"]
        return request
    }

    func unCategorizedMessages<T: ZMMessage>(for conversation: ZMConversation) -> [T] {
        precondition(
            conversation.managedObjectContext!.zm_isSyncContext,
            "Fetch should only be performed on the sync context"
        )

        let request: NSFetchRequest<T> = AssetCollectionBatched.fetchRequestForUnCategorizedMessages(in: conversation)
        request.fetchBatchSize = AssetCollectionBatched.defaultFetchCount

        guard let result = conversation.managedObjectContext?.fetchOrAssert(request: request) else {
            return []
        }
        return result
    }

    // MARK: Private

    private unowned var delegate: AssetCollectionDelegate
    private var assets: [CategoryMatch: [ZMMessage]]?
    private let conversation: ZMConversation?
    private let matchingCategories: [CategoryMatch]
    private var assetMessageOffset = 0
    private var clientMessageOffset = 0
    private var assetMessagesDone = false
    private var clientMessagesDone = false

    private var tornDown = false

    private var syncMOC: NSManagedObjectContext? {
        conversation?.managedObjectContext?.zm_sync
    }

    private var uiMOC: NSManagedObjectContext? {
        conversation?.managedObjectContext
    }

    private func setFetchingCompleteFor(type: MessagesToFetch) {
        if type == .client {
            clientMessagesDone = true
        } else {
            assetMessagesDone = true
        }
    }

    private func categorizeNextBatch(
        type: MessagesToFetch,
        allMessages: [ZMMessage],
        managedObjectContext: NSManagedObjectContext
    ) {
        guard !tornDown else {
            return
        }

        // get next offset
        let offset = (type == .asset) ? assetMessageOffset : clientMessageOffset
        let numberToAnalyze = min(allMessages.count - offset, AssetCollectionBatched.defaultFetchCount)
        if type == .asset {
            assetMessageOffset += numberToAnalyze
        } else {
            clientMessageOffset += numberToAnalyze
        }

        // check if we reached the last message
        let didReachLastMessage = (numberToAnalyze < AssetCollectionBatched.defaultFetchCount)
        if didReachLastMessage {
            setFetchingCompleteFor(type: type)
        }
        if numberToAnalyze == 0 {
            if fetchingDone {
                notifyDelegateFetchingIsDone(result: .success)
            }
            return
        }

        // Get and categorize next batch
        let messagesToAnalyze = Array(allMessages[offset ..< (offset + numberToAnalyze)])
        let newAssets = AssetCollectionBatched.messageMap(
            messages: messagesToAnalyze,
            matchingCategories: matchingCategories
        )
        managedObjectContext.enqueueDelayedSave()

        // Notify delegate
        notifyDelegate(newAssets: newAssets, type: type, didReachLastMessage: didReachLastMessage)

        // Return if done
        if didReachLastMessage {
            return
        }

        managedObjectContext.performGroupedBlock { [weak self] in
            guard let self, !self.tornDown else {
                return
            }
            categorizeNextBatch(type: type, allMessages: allMessages, managedObjectContext: managedObjectContext)
        }
    }

    private func notifyDelegate(
        newAssets: [CategoryMatch: [ZMMessage]],
        type: MessagesToFetch?,
        didReachLastMessage: Bool
    ) {
        if newAssets.isEmpty {
            return
        }
        uiMOC?.performGroupedBlock { [weak self] in
            guard let self, !self.tornDown else {
                return
            }

            // Map assets to UI assets
            var uiAssets = [CategoryMatch: [ZMMessage]]()
            newAssets.forEach {
                let uiValues = $1.compactMap { (try? self.uiMOC?.existingObject(with: $0.objectID)) as? ZMMessage }
                uiAssets[$0] = uiValues
            }

            // Merge result with existing result
            if let assets {
                self.assets = AssetCollectionBatched.merge(messageMap: assets, with: uiAssets)
            } else {
                assets = uiAssets
            }

            // Notify delegate
            delegate.assetCollectionDidFetch(collection: self, messages: uiAssets, hasMore: !didReachLastMessage)
            if fetchingDone {
                delegate.assetCollectionDidFinishFetching(collection: self, result: .success)
            }
        }
    }

    private func notifyDelegateFetchingIsDone(result: AssetFetchResult) {
        uiMOC?.performGroupedBlock { [weak self] in
            guard let self else {
                return
            }
            var result = result
            if result == .success {
                // Since we are setting the assets in a performGroupedBlock on the uiMOC, we might not know if there are
                // assets or not when we call notifyDelegateFetchingIsDone. Therefore we check for assets here.
                result = (assets != nil) ? .success : .noAssetsToFetch
            }
            delegate.assetCollectionDidFinishFetching(collection: self, result: result)
        }
    }
}

extension AssetCollectionBatched {
    static func messageMap(messages: [ZMMessage], matchingCategories: [CategoryMatch]) -> [CategoryMatch: [ZMMessage]] {
        precondition(!messages.isEmpty, "messages should contain at least one value")
        return AssetCollectionBatched.categorize(
            messages: messages,
            matchingCategories: matchingCategories
        )
    }

    static func categorize(messages: [ZMMessage], matchingCategories: [CategoryMatch])
        -> [CategoryMatch: [ZMMessage]] {
        // setup dictionary with keys we are interested in
        var sorted = [CategoryMatch: [ZMMessage]]()
        for matchPair in  matchingCategories {
            sorted[matchPair] = []
        }

        let unionIncluding: MessageCategory = matchingCategories.reduce(.none) { $0.union($1.including) }
        for message in messages {
            let category = message.cachedCategory
            guard category.intersection(unionIncluding) != .none,
                  !(category.contains(MessageCategory.excludedFromCollection))
            else {
                continue
            }

            for matchingCategory in matchingCategories {
                if category.contains(matchingCategory.including),
                   category.intersection(matchingCategory.excluding) == .none {
                    sorted[matchingCategory]?.append(message)
                }
            }
        }
        return sorted
    }

    static func merge(
        messageMap: [CategoryMatch: [ZMMessage]],
        with other: [CategoryMatch: [ZMMessage]]
    ) -> [CategoryMatch: [ZMMessage]]? {
        var newSortedMessages = [CategoryMatch: [ZMMessage]]()

        messageMap.forEach {
            var newValues = $1
            if let otherValues = other[$0] {
                newValues += otherValues
            }
            newSortedMessages[$0] = newValues
        }

        let newKeys = Set(other.keys).subtracting(Set(messageMap.keys))
        for newKey in newKeys {
            if let value = other[newKey] {
                newSortedMessages[newKey] = value
            }
        }

        return newSortedMessages
    }
}
