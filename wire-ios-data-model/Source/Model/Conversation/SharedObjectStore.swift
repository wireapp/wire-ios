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

extension Notification {
    fileprivate var contextDidSaveData: [AnyHashable: AnyObject] {
        guard let info = userInfo else { return [:] }
        var changes = [AnyHashable: AnyObject]()
        for (key, value) in info {
            guard let set = value as? NSSet else { continue }
            changes[key] = set.compactMap {
                ($0 as? NSManagedObject)?.objectID.uriRepresentation()
            } as AnyObject
        }

        return changes
    }
}

// MARK: - ContextDidSaveNotificationPersistence

/// This class is used to persist `NSManagedObjectContext` change
/// notifications in order to merge them into the main app contexts.
@objcMembers
public class ContextDidSaveNotificationPersistence: NSObject {
    // MARK: Lifecycle

    public required init(accountContainer url: URL) {
        self.objectStore = SharedObjectStore(accountContainer: url, fileName: "ContextDidChangeNotifications")
    }

    // MARK: Public

    public var storedNotifications: [[AnyHashable: AnyObject]] {
        objectStore.load()
    }

    @discardableResult
    public func add(_ note: Notification) -> Bool {
        objectStore.store(note.contextDidSaveData)
    }

    public func clear() {
        objectStore.clear()
    }

    // MARK: Private

    private let objectStore: SharedObjectStore<[AnyHashable: AnyObject]>
}

// MARK: - StorableTrackingEvent

@objcMembers
public class StorableTrackingEvent: NSObject {
    // MARK: Lifecycle

    public init(name: String, attributes: [String: Any]) {
        self.name = name
        self.attributes = attributes
    }

    public convenience init?(dictionary dict: [String: Any]) {
        guard let name = dict[StorableTrackingEvent.eventNameKey] as? String,
              var attributes = dict[StorableTrackingEvent.eventAttributesKey] as? [String: Any] else { return nil }
        attributes["timestamp"] = Date().transportString()
        self.init(name: name, attributes: attributes)
    }

    // MARK: Public

    public let name: String
    public let attributes: [String: Any]

    public func dictionaryRepresentation() -> [String: Any] {
        [
            StorableTrackingEvent.eventNameKey: name,
            StorableTrackingEvent.eventAttributesKey: attributes,
        ]
    }

    // MARK: Private

    private static let eventNameKey = "eventName"
    private static let eventAttributesKey = "eventAttributes"
}

// MARK: - ShareExtensionAnalyticsPersistence

@objcMembers
public class ShareExtensionAnalyticsPersistence: NSObject {
    // MARK: Lifecycle

    public required init(accountContainer url: URL) {
        self.objectStore = SharedObjectStore(accountContainer: url, fileName: "ShareExtensionAnalytics")
    }

    // MARK: Public

    public var storedTrackingEvents: [StorableTrackingEvent] {
        objectStore.load().compactMap(StorableTrackingEvent.init)
    }

    @discardableResult
    public func add(_ storableEvent: StorableTrackingEvent) -> Bool {
        objectStore.store(storableEvent.dictionaryRepresentation())
    }

    public func clear() {
        objectStore.clear()
    }

    // MARK: Private

    private let objectStore: SharedObjectStore<[String: Any]>
}

private let zmLog = ZMSLog(tag: "shared object store")

// MARK: - SharedObjectTestClass

// This class is needed to test unarchiving data saved before project rename
// It has to be added to WireDataModel module because it won't be resolved otherwise
class SharedObjectTestClass: NSObject, NSCoding {
    // MARK: Lifecycle

    override init() { self.flag = false }
    public required init?(coder aDecoder: NSCoder) { self.flag = aDecoder.decodeBool(forKey: "flag") }

    // MARK: Public

    public func encode(with aCoder: NSCoder) { aCoder.encode(flag, forKey: "flag") }

    // MARK: Internal

    var flag: Bool
}

// MARK: - SharedObjectStore

/// This class is used to persist objects in a shared directory
public class SharedObjectStore<T>: NSObject, NSKeyedUnarchiverDelegate {
    // MARK: Lifecycle

    public required init(accountContainer: URL, fileName: String) {
        self.directory = accountContainer.appendingPathComponent(directoryName)
        self.url = directory.appendingPathComponent(fileName)
        super.init()
        try! FileManager.default.createAndProtectDirectory(at: directory)
    }

    // MARK: Public

    @discardableResult
    public func store(_ object: T) -> Bool {
        do {
            var current = load()
            current.append(object)
            let archived = try NSKeyedArchiver.archivedData(withRootObject: current, requiringSecureCoding: false)
            try archived.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            zmLog.debug("Stored object in shared container at \(url), object: \(object), all objects: \(current)")
            return true
        } catch {
            zmLog.error("Failed to write to url: \(url), error: \(error), object: \(object)")
            return false
        }
    }

    public func load() -> [T] {
        if !fileManager.fileExists(atPath: url.path) {
            zmLog.debug("Skipping loading shared file as it does not exist")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false
            unarchiver.delegate = self // If we are loading data saved before project rename the class will not be found
            let stored = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [T]
            zmLog.debug("Loaded shared objects from \(url): \(String(describing: stored))")
            return stored ?? []
        } catch {
            zmLog.error("Failed to read from url: \(url), error: \(error)")
            return []
        }
    }

    public func unarchiver(
        _ unarchiver: NSKeyedUnarchiver,
        cannotDecodeObjectOfClassName name: String,
        originalClasses classNames: [String]
    ) -> Swift.AnyClass? {
        let oldModulePrefix = "ZMCDataModel"
        if let modulePrefixRange = name.range(of: oldModulePrefix) {
            let fixedName = name.replacingCharacters(in: modulePrefixRange, with: "WireDataModel")
            return NSClassFromString(fixedName)
        }
        return nil
    }

    public func clear() {
        do {
            guard fileManager.fileExists(atPath: url.path) else { return }
            try fileManager.removeItem(at: url)
            zmLog.debug("Cleared shared objects from \(url)")
        } catch {
            zmLog.error("Failed to remove item at url: \(url), error: \(error)")
        }
    }

    // MARK: Private

    private let directory: URL
    private let url: URL
    private let fileManager = FileManager.default
    private let directoryName = "sharedObjectStore"
}
