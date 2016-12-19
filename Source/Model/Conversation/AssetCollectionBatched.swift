//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


/// This class fetches messages and groups them by `MessageCategory` (e.g. files, images, videos etc.)
/// It first fetches all objects that have previously categorized and then performs one fetch request with fetchBatchSize set. CoreData returns an array  proxy to us that is populated with objects as we iterate through the array. Core Data will get rid of objects again, as they’re no longer accessed.
/// For every categorized batch it will call the delegate with the newly categorized objects and then once again when it finished categorizing all objects
public class AssetCollectionBatched : NSObject, ZMCollection {
    
    private unowned var delegate : AssetCollectionDelegate
    private var assets : Dictionary<MessageCategory, [ZMMessage]>?
    private let conversation: ZMConversation
    private let including : [MessageCategory]
    private let excluding: MessageCategory
    private var allAssetMessages: [ZMAssetClientMessage] = []
    private var allClientMessages: [ZMClientMessage] = []

    enum MessagesToFetch {
        case client, asset
    }
    
    public static let defaultFetchCount = 200
    
    private var tornDown = false
    
    private var syncMOC: NSManagedObjectContext? {
        return conversation.managedObjectContext?.zm_sync
    }
    private var uiMOC: NSManagedObjectContext? {
        return conversation.managedObjectContext
    }
    
    /// Returns true when there are no assets to fetch OR when all assets have been processed OR the collection has been tornDown
    public var doneFetching : Bool {
        return tornDown || (allAssetMessages.count == 0 && allClientMessages.count == 0)
    }
    
    /// Returns a collection that automatically fetches the assets in batches
    /// @param including: The AssetCollection only returns and calls the delegate for these categories
    /// @param excluding: These categories are excluded when fetching messages (e.g if you want files, but not videos)
    public init(conversation: ZMConversation, including : [MessageCategory], excluding: [MessageCategory] = [],  delegate: AssetCollectionDelegate){
        self.conversation = conversation
        self.delegate = delegate
        self.including = including
        self.excluding = excluding.reduce(.none){$0.union($1)}

        super.init()
        
        syncMOC?.performGroupedBlock {
            guard !self.tornDown else { return }
            guard let syncConversation = (try? self.syncMOC?.existingObject(with: self.conversation.objectID)) as? ZMConversation else {
                return
            }
            self.allAssetMessages = self.unCategorizedMessages(for: syncConversation)
            self.allClientMessages = self.unCategorizedMessages(for: syncConversation)
            
            let categorizedMessages : [ZMMessage] = self.categorizedMessages(for: syncConversation)
            if categorizedMessages.count > 0 {
                let categorized = AssetCollectionBatched.messageMap(messages: categorizedMessages, including: self.including, excluding: self.excluding)
                self.assets = categorized
                self.notifyDelegate(newAssets: self.assets!, type: nil)
            }

            self.categorizeNextBatch(type: .asset)
            self.categorizeNextBatch(type: .client)
        }
    }
    
    /// Cancels further fetch requests
    public func tearDown() {
        tornDown = true
    }
    
    deinit {
        precondition(tornDown, "Call tearDown to avoid continued fetch requests")
    }
    
    /// Returns all assets that have been fetched thus far
    public func assets(for category: MessageCategory) -> [ZMMessage] {
        // Remove zombie objects and return remaining
        if let values = assets?[category] {
            let withoutZombie = values.filter{!$0.isZombieObject}
            assets?[category] = withoutZombie
            return withoutZombie
        }
        return []
    }
    
    private func categorizeNextBatch(type: MessagesToFetch){
        guard !tornDown else { return }
        
        // get next batch to categorize
        let messages : [ZMMessage] = (type == .asset) ? self.allAssetMessages : self.allClientMessages
        let numberToAnalyze = min(messages.count, AssetCollectionBatched.defaultFetchCount)
        if numberToAnalyze == 0 {
            if self.doneFetching {
                self.notifyDelegateFetchingIsDone(result: .success)
            }
            return
        }
        let messagesToAnalyze = Array(messages[0..<numberToAnalyze])
        
        // categorize batch
        let newAssets = AssetCollectionBatched.messageMap(messages: messagesToAnalyze, including: self.including, excluding: self.excluding)
        
        // Remove analyzed results from fetched messages
        // TODO Sabine: I am not sure what effect this has on the array proxy we received through the fetch. The alternative would be storing the offset
        // Profile this!
        if type == .asset {
            self.allAssetMessages = Array(self.allAssetMessages.dropFirst(numberToAnalyze))
        } else {
            self.allClientMessages = Array(self.allClientMessages.dropFirst(numberToAnalyze))
        }
        
        // Notify delegate
        self.notifyDelegate(newAssets: newAssets, type: type)
        
        // Return if done
        if self.doneFetching {
            return
        }
        
        syncMOC?.performGroupedBlock { [weak self] in
            guard let `self` = self, !self.tornDown else { return }
            self.categorizeNextBatch(type: type)
        }
    }
    
    private func notifyDelegate(newAssets: [MessageCategory : [ZMMessage]], type: MessagesToFetch?) {
        if newAssets.count == 0 {
            return
        }
        uiMOC?.performGroupedBlock { [weak self] in
            guard let `self` = self, !self.tornDown else { return }
            
            // Map assets to UI assets
            var uiAssets = [MessageCategory : [ZMMessage]]()
            newAssets.forEach {
                let uiValues = $1.flatMap{ (try? self.uiMOC?.existingObject(with: $0.objectID)) as? ZMMessage}
                uiAssets[$0] = uiValues
            }
            
            // Merge result with existing result
            if let assets = self.assets {
                self.assets = AssetCollectionBatched.merge(messageMap: assets, with: uiAssets)
            } else {
                self.assets = uiAssets
            }

            // Notify delegate
            let hasMore : Bool
            switch type {
            case .some(.client): hasMore = self.allClientMessages.count != 0
            case .some(.asset):  hasMore = self.allAssetMessages.count != 0
            case .none:          hasMore = !self.doneFetching
            }
            self.delegate.assetCollectionDidFetch(collection: self, messages: uiAssets, hasMore: hasMore)
            if self.doneFetching {
                self.delegate.assetCollectionDidFinishFetching(collection: self, result: .success)
            }
        }
    }
    
    private func notifyDelegateFetchingIsDone(result: AssetFetchResult){
        self.uiMOC?.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }
            var result = result
            if result == .success {
                // Since we are setting the assets in a performGroupedBlock on the uiMOC, we might not know if there are assets or not when we call notifyDelegateFetchingIsDone. Therefore we check for assets here.
                result = (self.assets != nil) ? .success : .noAssetsToFetch
            }
            self.delegate.assetCollectionDidFinishFetching(collection: self, result: result)
        }
    }
    
    func categorizedMessages<T : ZMMessage>(for conversation: ZMConversation) -> [T] {
        precondition(conversation.managedObjectContext!.zm_isSyncContext, "Fetch should only be performed on the sync context")
        let request = T.fetchRequestMatching(categories: Set(self.including), excluding: self.excluding, conversation: conversation)
        
        guard let result = conversation.managedObjectContext?.fetchOrAssert(request: request as! NSFetchRequest<T>) else {return []}
        return result
    }
    
    func unCategorizedMessages<T : ZMMessage>(for conversation: ZMConversation) -> [T]  {
        precondition(conversation.managedObjectContext!.zm_isSyncContext, "Fetch should only be performed on the sync context")
        
        let request : NSFetchRequest<T> = AssetCollectionBatched.fetchRequestForUnCategorizedMessages(in: conversation)
        request.fetchBatchSize = AssetCollectionBatched.defaultFetchCount
        
        guard let result = conversation.managedObjectContext?.fetchOrAssert(request: request) else {return []}
        return result
    }
    
    static func fetchRequestForUnCategorizedMessages<T : ZMMessage>(in conversation: ZMConversation) -> NSFetchRequest<T> {
        let request = NSFetchRequest<T>(entityName: T.entityName())
        request.predicate = NSPredicate(format: "visibleInConversation == %@ && (%K == NULL || %K == %d)",
                                        conversation,
                                        ZMMessageCachedCategoryKey,
                                        ZMMessageCachedCategoryKey, MessageCategory.none.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "serverTimestamp", ascending: false)]
        request.relationshipKeyPathsForPrefetching = ["dataSet"]
        return request
    }
}



extension AssetCollectionBatched  {
    
    
    static func messageMap(messages: [ZMMessage], including: [MessageCategory], excluding: MessageCategory) -> Dictionary<MessageCategory, [ZMMessage]> {
        precondition(messages.count > 0, "messages should contain at least one value")
        let messagesByFilter = AssetCollectionBatched.categorize(messages: messages, including: including, excluding:excluding)
        return messagesByFilter
    }
    
    static func categorize(messages: [ZMMessage], including: [MessageCategory], excluding: MessageCategory)
        -> [MessageCategory : [ZMMessage]]
    {
        // setup dictionary with keys we are interested in
        var sorted = [MessageCategory : [ZMMessage]]()
        for category in including {
            sorted[category] = []
        }
        
        let unionIncluding : MessageCategory = including.reduce(.none){$0.union($1)}
        messages.forEach{ message in
            let category = message.cachedCategory
            guard (category.intersection(unionIncluding) != .none) && (category.intersection(excluding) == .none) else { return }

            including.forEach {
                if category.contains($0) {
                    sorted[$0]?.append(message)
                }
            }
        }
        return sorted
    }
    
    static func merge(messageMap: Dictionary<MessageCategory, [ZMMessage]>, with other: Dictionary<MessageCategory, [ZMMessage]>) -> Dictionary<MessageCategory, [ZMMessage]>? {
        var newSortedMessages = [MessageCategory : [ZMMessage]]()

        messageMap.forEach {
            var newValues = $1
            if let otherValues = other[$0] {
                newValues = newValues + otherValues
            }
            newSortedMessages[$0] = newValues
        }
        
        let newKeys = Set(other.keys).subtracting(Set(messageMap.keys))
        newKeys.forEach{
            if let value = other[$0] {
                newSortedMessages[$0] = value
            }
        }
        
        return newSortedMessages
    }
    
}


