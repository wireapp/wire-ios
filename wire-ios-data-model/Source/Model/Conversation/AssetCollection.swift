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
import WireUtilities

public enum AssetFetchResult: Int {
    case success, failed, noAssetsToFetch
}

public protocol ZMCollection: TearDownCapable {
    func tearDown()
    func assets(for category: CategoryMatch) -> [ZMConversationMessage]
    var fetchingDone: Bool { get }
}

public protocol AssetCollectionDelegate: NSObjectProtocol {
    /// The AssetCollection calls this when the fetching completes
    /// To get all messages for any category defined in `including`, call `assets(for category: CategoryMatch)`
    func assetCollectionDidFetch(
        collection: ZMCollection,
        messages: [CategoryMatch: [ZMConversationMessage]],
        hasMore: Bool
    )

    /// This method is called when all assets in the conversation have been fetched & analyzed / categorized
    func assetCollectionDidFinishFetching(collection: ZMCollection, result: AssetFetchResult)
}

/// This class fetches messages and groups them by `CategoryMatch` (e.g. files, images, videos etc.)
/// It first fetches all objects that have previously categorized and then performs consecutive request of limited
/// batch-size and categorizes them
/// For every categorized batch it will call the delegate with the newly categorized objects and then once again when it
/// finished categorizing all objects
public class AssetCollection: NSObject, ZMCollection {
    private unowned var delegate: AssetCollectionDelegate
    private var assets: [CategoryMatch: [ZMMessage]]?
    private var lastAssetMessage: ZMAssetClientMessage?
    private var lastClientMessage: ZMClientMessage?
    private let conversation: ZMConversation?
    private let matchingCategories: [CategoryMatch]

    enum MessagesToFetch {
        case client, asset
    }

    public static let initialFetchCount = 100
    public static let defaultFetchCount = 500
    public private(set) var doneFetchingAssets = false
    public private(set) var doneFetchingTexts = false

    private var tornDown = false {
        didSet {
            doneFetchingAssets = true
            doneFetchingTexts = true
        }
    }

    public var fetchingDone: Bool {
        doneFetchingTexts && doneFetchingAssets
    }

    private var syncMOC: NSManagedObjectContext? {
        conversation?.managedObjectContext?.zm_sync
    }

    private var uiMOC: NSManagedObjectContext? {
        conversation?.managedObjectContext
    }

    /// Returns a collection that automatically fetches the assets in batches
    /// @param categoriesToFetch: The AssetCollection only returns and calls the delegate for these categories
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
            guard let self, !self.tornDown else { return }
            guard let conversation = self.conversation,
                  let syncConversation = (try? syncMOC.existingObject(with: conversation.objectID)) as? ZMConversation
            else {
                return
            }

            let categorizedMessages: [ZMMessage] = AssetCollectionBatched.categorizedMessages(
                for: syncConversation,
                matchPairs: self.matchingCategories
            )
            if !categorizedMessages.isEmpty {
                let categorized = AssetCollectionBatched.messageMap(
                    messages: categorizedMessages,
                    matchingCategories: self.matchingCategories
                )
                notifyDelegate(newAssets: categorized, type: nil, didReachLastMessage: false)
            }

            fetchNextIfNotTornDown(
                limit: AssetCollection.initialFetchCount,
                type: .asset,
                syncConversation: syncConversation
            )
            fetchNextIfNotTornDown(
                limit: AssetCollection.initialFetchCount,
                type: .client,
                syncConversation: syncConversation
            )
        }
    }

    /// Cancels further fetch requests
    public func tearDown() {
        tornDown = true
        doneFetchingAssets = true
        doneFetchingTexts = true
    }

    deinit {
        precondition(tornDown, "Call tearDown to avoid continued fetch requests")
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

    private func setFetchingCompleteFor(type: MessagesToFetch) {
        if type == .client {
            doneFetchingTexts = true
        } else {
            doneFetchingAssets = true
        }
    }

    // NB: Method is expected to be run only on sync queue.
    private func fetchNextIfNotTornDown(limit: Int, type: MessagesToFetch, syncConversation: ZMConversation) {
        guard !fetchingDone, !tornDown else { return }
        guard !syncConversation.isZombieObject else {
            notifyDelegateFetchingIsDone(result: .failed)
            return
        }

        // Fetch next messages to categorize
        let lastMessage: ZMMessage? = (type == .client) ? lastClientMessage : lastAssetMessage
        let messagesToAnalyze: [ZMMessage]
        if  type == .client {
            // Unfortunately this is the only way to infer the type :-/
            let clientMessages: [ZMClientMessage] = messages(
                for: syncConversation,
                startAfter: lastMessage,
                fetchLimit: limit
            )
            messagesToAnalyze = clientMessages
        } else {
            let assetMessages: [ZMAssetClientMessage] = messages(
                for: syncConversation,
                startAfter: lastMessage,
                fetchLimit: limit
            )
            messagesToAnalyze = assetMessages
        }

        // Determine whether we have reached the end of the messages, if so, set flags for completeness
        let didReachLastMessage = (messagesToAnalyze.count < limit)
        if didReachLastMessage {
            setFetchingCompleteFor(type: type)
        }
        if messagesToAnalyze.isEmpty {
            if fetchingDone {
                notifyDelegateFetchingIsDone(result: (assets == nil) ? .noAssetsToFetch : .success)
            }
            return
        }

        // Remember last message for next fetch
        if type == .client {
            lastClientMessage = messagesToAnalyze.last as? ZMClientMessage
        } else {
            lastAssetMessage = messagesToAnalyze.last as? ZMAssetClientMessage
        }

        // Categorize messages
        let newAssets = AssetCollectionBatched.messageMap(
            messages: messagesToAnalyze,
            matchingCategories: matchingCategories
        )
        syncConversation.managedObjectContext?.enqueueDelayedSave()

        // Notify delegate
        notifyDelegate(newAssets: newAssets, type: type, didReachLastMessage: didReachLastMessage)

        // Return if done
        if didReachLastMessage {
            return
        }

        syncConversation.managedObjectContext?.performGroupedBlock { [weak self] in
            guard let self, !self.tornDown else { return }
            fetchNextIfNotTornDown(
                limit: AssetCollection.defaultFetchCount,
                type: type,
                syncConversation: syncConversation
            )
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
            guard let self, !self.tornDown else { return }

            // Map to ui assets
            var uiAssets = [CategoryMatch: [ZMMessage]]()
            for (category, messages) in newAssets {
                let uiValues = messages
                    .compactMap { (try? self.uiMOC?.existingObject(with: $0.objectID)) as? ZMMessage }
                uiAssets[category] = uiValues
            }

            // Merge with existing assets
            if let assets {
                self.assets = AssetCollectionBatched.merge(messageMap: assets, with: uiAssets)
            } else {
                assets = uiAssets
            }

            // Notify delegate
            delegate.assetCollectionDidFetch(collection: self, messages: uiAssets, hasMore: didReachLastMessage)
            if fetchingDone {
                notifyDelegateFetchingIsDone(result: (assets == nil) ? .noAssetsToFetch : .success)
            }
        }
    }

    private func notifyDelegateFetchingIsDone(result: AssetFetchResult) {
        uiMOC?.performGroupedBlock { [weak self] in
            guard let self, !self.tornDown else { return }
            delegate.assetCollectionDidFinishFetching(collection: self, result: result)
        }
    }

    func messages<T: ZMMessage>(
        for conversation: ZMConversation,
        startAfter previousMessage: ZMMessage?,
        fetchLimit: Int
    ) -> [T] {
        let request: NSFetchRequest<T> = AssetCollectionBatched.fetchRequestForUnCategorizedMessages(in: conversation)
        if let serverTimestamp = previousMessage?.serverTimestamp {
            let messagePredicate = NSPredicate(format: "serverTimestamp < %@", serverTimestamp as NSDate)
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                request.predicate!,
                messagePredicate,
            ])
        }
        request.fetchLimit = fetchLimit
        request.returnsObjectsAsFaults = false

        guard let result = conversation.managedObjectContext?.fetchOrAssert(request: request) else { return [] }
        return result
    }
}
