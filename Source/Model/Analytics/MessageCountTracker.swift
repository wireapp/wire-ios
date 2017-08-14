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


private let log = ZMSLog(tag: "MessageCountTracker")


public struct MessageCount {
    let unencryptedImageCount: Int
    let plaintextMessageCount: Int
    let clientMessageCount: Int
    let assetClientMessageCount: Int
}


fileprivate struct MessageCountEvent {
    let name = "message_count"
    let attributes: [String: NSObject]

    init(messageCount: MessageCount, databaseSize: UInt) {
        let clusterizer = IntegerClusterizer.messageCount
        attributes = [
            "database_size_mb": IntegerClusterizer.databaseSize.clusterize(Int(databaseSize / 1_000_000)) as NSObject,
            "unencrypted_images": clusterizer.clusterize(messageCount.unencryptedImageCount) as NSObject,
            "unencrypted_text": clusterizer.clusterize(messageCount.plaintextMessageCount) as NSObject,
            "asset_messages": clusterizer.clusterize(messageCount.assetClientMessageCount) as NSObject,
            "client_messages": clusterizer.clusterize(messageCount.clientMessageCount) as NSObject
        ]
    }
}


public protocol CountFetcherType {
    func fetchNumberOfLegacyMessages(_ completion: @escaping (MessageCount) -> Void)
}


final fileprivate class LegacyMessageCountFetcher: CountFetcherType {

    private let managedObjectContext: NSManagedObjectContext

    /// Creates a new instance of a `LegcayMessageCountFetcher`.
    /// The passed `NSManagedObjectContext` needs to be the sync MOC.
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    private func numberOfPlainTextMessages() -> Int {
        do {
            guard let request = ZMTextMessage.sortedFetchRequest() else { return 0 }
            return try managedObjectContext.count(for: request)
        } catch {
            log.error("Unable to get count of plain text messages in database: \(error)")
            return 0
        }
    }

    private func numberOfUnencryptedImageMessages() -> Int {
        do {
            guard let request = ZMImageMessage.sortedFetchRequest() else { return 0 }
            return try managedObjectContext.count(for: request)
        } catch {
            log.error("Unable to get count of unencrypted image messages in database: \(error)")
            return 0
        }
    }

    private func numberOfAssetClientMessages() -> Int {
        do {
            guard let request = ZMAssetClientMessage.sortedFetchRequest() else { return 0 }
            return try managedObjectContext.count(for: request)
        } catch {
            log.error("Unable to get count of asset client messages in database: \(error)")
            return 0
        }
    }

    private func numberOfClientMessages() -> Int {
        do {
            guard let request = ZMClientMessage.sortedFetchRequest() else { return 0 }
            return try managedObjectContext.count(for: request)
        } catch {
            log.error("Unable to get count of client messages in database: \(error)")
            return 0
        }
    }

    /// Fetches the number of legacy (unencrypted) image and text messages in the database and 
    /// calls the completion handler with the result.
    /// Safe to be called from any thread as it dispatches on the context passed to `init`.
    /// The completion handler will be called on the NSManagedObjectContext queue passed to `init`.
    fileprivate func fetchNumberOfLegacyMessages(_ completion: @escaping (MessageCount) -> Void) {
        managedObjectContext.performGroupedBlock {
            let messageCount = MessageCount(
                unencryptedImageCount: self.numberOfUnencryptedImageMessages(),
                plaintextMessageCount: self.numberOfPlainTextMessages(),
                clientMessageCount: self.numberOfClientMessages(),
                assetClientMessageCount: self.numberOfAssetClientMessages()
            )
            completion(messageCount)
        }
    }

}


private let debugTrackingOverride = false


@objc final public class LegacyMessageTracker: NSObject {

    private let lastTrackDateKey = "LegacyMessageTracker.lastTrackDate"

    private let managedObjectContext: NSManagedObjectContext
    private let userDefaults: UserDefaults
    private let createDate: () -> Date
    private let countFetcher: CountFetcherType
    private let dayThreshold = 14

    @objc public convenience init?(managedObjectContext: NSManagedObjectContext) {
        self.init(
            managedObjectContext: managedObjectContext,
            userDefaults: .standard,
            createDate: Date.init
        )
    }

    convenience init?(managedObjectContext: NSManagedObjectContext, userDefaults: UserDefaults, createDate: @escaping () -> Date) {
        self.init(
            managedObjectContext: managedObjectContext,
            userDefaults: userDefaults,
            createDate: createDate,
            countFetcher: LegacyMessageCountFetcher(managedObjectContext: managedObjectContext)
        )
    }

    init?(
        managedObjectContext: NSManagedObjectContext,
        userDefaults: UserDefaults,
        createDate: @escaping () -> Date,
        countFetcher: CountFetcherType
        ) {
        self.managedObjectContext = managedObjectContext
        self.countFetcher = countFetcher
        self.userDefaults = userDefaults
        self.createDate = createDate
        super.init()
    }

    var lastTrackDate: Date? {
        get { return userDefaults.object(forKey: lastTrackDateKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastTrackDateKey) }
    }

    func shouldTrack() -> Bool {
        guard let lastDate = lastTrackDate else { return true }
        guard let days = Calendar.current.dateComponents([.day], from: lastDate, to: createDate()).day else { return true }
        return days >= dayThreshold
    }

    public func trackLegacyMessageCount() {
        guard shouldTrack() || debugTrackingOverride else { return }
        lastTrackDate = createDate()
        countFetcher.fetchNumberOfLegacyMessages {
            let event = MessageCountEvent(messageCount: $0, databaseSize: self.databaseSize() ?? 0)
            self.managedObjectContext.analytics?.tagEvent(event.name, attributes: event.attributes)
        }
    }

    private func databaseSize() -> UInt? {
        guard let storeURL = managedObjectContext.zm_storeURL?.path else { return 0 }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL)
            return attributes[FileAttributeKey.size] as? UInt
        } catch {
            log.error("Unable to retrieve database attributes: \(error), path: \(storeURL)")
            return nil
        }
    }
}

