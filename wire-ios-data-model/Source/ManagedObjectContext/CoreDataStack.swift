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
import Foundation
import WireSystem
import WireUtilities

// MARK: - CoreDataStackError

enum CoreDataStackError: Error {
    case simulateDatabaseLoadingFailure
    case noDatabaseActivity
}

// MARK: LocalizedError

extension CoreDataStackError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .simulateDatabaseLoadingFailure:
            "simulateDatabaseLoadingFailure"
        case .noDatabaseActivity:
            "Could not create a background activity for database setup"
        }
    }
}

// MARK: - ContextProvider

@objc
public protocol ContextProvider {
    var account: Account { get }

    var viewContext: NSManagedObjectContext { get }
    var syncContext: NSManagedObjectContext { get }
    var searchContext: NSManagedObjectContext { get }
    var eventContext: NSManagedObjectContext { get }
}

extension URL {
    /// Appends a suffix to the last path (e.g. from `/foo/bar` to `/foo/bar_1`)
    func appendingSuffixToLastPathComponent(suffix: String) -> URL {
        let modifiedComponent = lastPathComponent + suffix
        return deletingLastPathComponent().appendingPathComponent(modifiedComponent)
    }

    /// Appends the name of the store to the path
    func appendingStoreFile() -> URL {
        appendingPathComponent("store.wiredatabase")
    }

    func appendingEventStoreFile() -> URL {
        appendingPathComponent("ZMEventModel.sqlite")
    }

    /// Returns the location of the persistent store file in the given account folder
    func appendingPersistentStoreLocation() -> URL {
        appendingPathComponent("store").appendingStoreFile()
    }

    /// Returns the location of the persistent store file in the given account folder
    func appendingEventStoreLocation() -> URL {
        appendingPathComponent("events").appendingEventStoreFile()
    }

    func appendingSessionStoreFolder() -> URL {
        appendingPathComponent("otr")
    }

    func appendingStoreSupportFolder() -> URL {
        let storeFile = appendingStoreFile()
        let storeName = storeFile.deletingPathExtension().lastPathComponent
        let storeDirectory = deletingLastPathComponent()
        let supportFile = ".\(storeName)_SUPPORT"
        return storeDirectory.appendingPathComponent(supportFile)
    }
}

extension NSURL {
    /// Returns the location of the persistent store file in the given account folder
    @objc
    public func URLByAppendingPersistentStoreLocation() -> URL {
        (self as URL).appendingPersistentStoreLocation()
    }
}

// MARK: - CoreDataStack

@objcMembers
public class CoreDataStack: NSObject, ContextProvider {
    public let account: Account

    public var viewContext: NSManagedObjectContext {
        messagesContainer.viewContext
    }

    public lazy var syncContext: NSManagedObjectContext = messagesContainer.newBackgroundContext()

    public lazy var searchContext: NSManagedObjectContext = messagesContainer.newBackgroundContext()

    public lazy var eventContext: NSManagedObjectContext = eventsContainer.newBackgroundContext()

    public let accountContainer: URL
    public let applicationContainer: URL

    let messagesContainer: PersistentContainer
    let eventsContainer: PersistentContainer
    let dispatchGroup: ZMSDispatchGroup?

    private let messagesMigrator: CoreDataMigrator<CoreDataMessagingMigrationVersion>
    private let eventsMigrator: CoreDataMigrator<CoreDataEventsMigrationVersion>
    private var hasBeenClosed = false

    // MARK: - Initialization

    public init(
        account: Account,
        applicationContainer: URL,
        inMemoryStore: Bool = false,
        dispatchGroup: ZMSDispatchGroup? = nil
    ) {
        ExtendedSecureUnarchiveFromData.register()

        self.applicationContainer = applicationContainer
        self.account = account
        self.dispatchGroup = dispatchGroup

        let accountDirectory = Self.accountDataFolder(
            accountIdentifier: account.userIdentifier,
            applicationContainer: applicationContainer
        )

        self.accountContainer = accountDirectory

        let eventContainer = PersistentContainer(name: "ZMEventModel")
        let messagesContainer = PersistentContainer(name: "zmessaging")

        let description: NSPersistentStoreDescription
        let eventStoreDescription: NSPersistentStoreDescription

        if inMemoryStore {
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType

            eventStoreDescription = NSPersistentStoreDescription()
            eventStoreDescription.type = NSInMemoryStoreType
        } else {
            let storeURL = accountDirectory.appendingPersistentStoreLocation()
            description = NSPersistentStoreDescription(url: storeURL)

            // https://www.sqlite.org/pragma.html
            description.setValue(
                "WAL" as NSObject,
                forPragmaNamed: "journal_mode"
            )
            description.setValue(
                "FULL" as NSObject,
                forPragmaNamed: "synchronous"
            )
            description.setValue(
                "TRUE" as NSObject,
                forPragmaNamed: "secure_delete"
            )

            let eventStoreURL = accountDirectory.appendingEventStoreLocation()
            eventStoreDescription = NSPersistentStoreDescription(url: eventStoreURL)
        }

        messagesContainer.persistentStoreDescriptions = [description]
        eventContainer.persistentStoreDescriptions = [eventStoreDescription]

        self.messagesContainer = messagesContainer
        self.eventsContainer = eventContainer
        self.messagesMigrator = CoreDataMigrator(isInMemoryStore: inMemoryStore)
        self.eventsMigrator = CoreDataMigrator(isInMemoryStore: inMemoryStore)

        super.init()

        clearStorageIfNecessary()
    }

    deinit {
        close()
    }

    public func close() {
        guard !hasBeenClosed  else {
            return
        }

        defer { hasBeenClosed = true }

        viewContext.tearDown()
        syncContext.tearDown()
        searchContext.tearDown()
        eventContext.tearDown()
        closeStores()
    }

    func closeStores() {
        WireLogger.localStorage.info("Closing core data stores")
        do {
            try closeStores(in: messagesContainer)
            try closeStores(in: eventsContainer)
        } catch {
            WireLogger.localStorage.error("Error while closing persistent store: \(error)", attributes: .safePublic)
        }
    }

    func closeStores(in container: PersistentContainer) throws {
        try container.persistentStoreCoordinator.persistentStores.forEach {
            try container.persistentStoreCoordinator.remove($0)
        }
    }

    public func setup(
        onStartMigration: () -> Void,
        onFailure: @escaping (Error) -> Void,
        onCompletion: @escaping (CoreDataStack) -> Void
    ) {
        if needsMigration {
            onStartMigration()
        }
        DispatchQueue.global(qos: .userInitiated).async {
            if self.needsMessagingStoreMigration() {
                let tp = TimePoint(interval: 60.0, label: "db migration")
                WireLogger.localStorage.info(
                    "[setup] start migration of core data messaging store!",
                    attributes: .safePublic
                )

                do {
                    try self.migrateMessagingStore()
                    WireLogger.localStorage.info(
                        "[setup] finished migration of core data messaging store!",
                        attributes: .safePublic
                    )
                } catch {
                    let logMessage =
                        "[setup] failed migration of core data messaging store: \(error.localizedDescription)."
                    WireLogger.localStorage.error(logMessage, attributes: .safePublic)

                    DispatchQueue.main.async {
                        onFailure(error)
                    }
                    return
                }
                if tp.warnIfLongerThanInterval() == false {
                    WireLogger.localStorage.info(
                        "time spent in migration only: \(tp.elapsedTime)",
                        attributes: .safePublic
                    )
                }
            }

            if self.needsEventStoreMigration() {
                let tp = TimePoint(interval: 60.0, label: "db migration")
                WireLogger.localStorage.info(
                    "[setup] start migration of core data event store!",
                    attributes: .safePublic
                )

                do {
                    try self.migrateEventStore()
                    WireLogger.localStorage.info(
                        "[setup] finished migration of core data event store!",
                        attributes: .safePublic
                    )
                } catch {
                    let logMessage = "[setup] failed migration of core data event store: \(error.localizedDescription)."
                    WireLogger.localStorage.error(logMessage, attributes: .safePublic)

                    DispatchQueue.main.async {
                        onFailure(error)
                    }
                    return
                }
                if tp.warnIfLongerThanInterval() == false {
                    WireLogger.localStorage.info(
                        "time spent in migration only: \(tp.elapsedTime)",
                        attributes: .safePublic
                    )
                }
            }

            DispatchQueue.main.async {
                WireLogger.localStorage.info("[setup] load core data stores!", attributes: .safePublic)
                self.loadStores { error in
                    if DeveloperFlag.forceDatabaseLoadingFailure.isOn {
                        // flip off the flag in order not to be stuck in failure
                        var flag = DeveloperFlag.forceDatabaseLoadingFailure
                        flag.isOn = false
                        onFailure(CoreDataStackError.simulateDatabaseLoadingFailure)
                        return
                    }

                    if let error {
                        onFailure(error)
                        return
                    }
                    onCompletion(self)
                }
            }
        }
    }

    public func loadStores(completionHandler: @escaping (Error?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var loadingStoreError: Error?

        dispatchGroup.enter()
        loadMessagesStore { error in
            if let error {
                WireLogger.localStorage.error("failed to load message store: \(error)", attributes: .safePublic)
            }
            loadingStoreError = loadingStoreError ?? error
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        loadEventStore { error in
            if let error {
                WireLogger.localStorage.error("failed to load event store: \(error)")
            }
            loadingStoreError = loadingStoreError ?? error
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            completionHandler(loadingStoreError)
        }
    }

    func loadMessagesStore(completionHandler: @escaping (Error?) -> Void) {
        do {
            try createStoreDirectory(for: messagesContainer)
        } catch {
            completionHandler(error)
            return
        }

        messagesContainer.loadPersistentStores { _, error in

            guard error == nil else {
                completionHandler(error)
                return
            }

            self.configureContextReferences()
            self.configureViewContext(self.viewContext)
            self.configureSyncContext(self.syncContext)
            self.configureSearchContext(self.searchContext)

            completionHandler(nil)
        }
    }

    func loadEventStore(completionHandler: @escaping (Error?) -> Void) {
        do {
            try createStoreDirectory(for: eventsContainer)
        } catch {
            completionHandler(error)
            return
        }

        eventsContainer.loadPersistentStores { _, error in

            guard error == nil else {
                completionHandler(error)
                return
            }

            self.configureEventContext(self.eventContext)

            completionHandler(nil)
        }
    }

    func createStoreDirectory(for container: PersistentContainer) throws {
        let storeURL = container.persistentStoreDescriptions.first?.url
        if let url = storeURL?.deletingLastPathComponent() {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    public var needsMigration: Bool {
        needsMessagingStoreMigration() || eventsContainer.needsMigration
    }

    public var storesExists: Bool {
        messagesContainer.storeExists && eventsContainer.storeExists
    }

    // MARK: - Configure Contexts

    func configureViewContext(_ context: NSManagedObjectContext) {
        context.markAsUIContext()
        context.createDispatchGroups()
        dispatchGroup.map(context.addGroup(_:))
        context.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
        ZMUser.selfUser(in: context)
        Label.fetchOrCreateFavoriteLabel(in: context, create: true)
    }

    func configureContextReferences() {
        viewContext.performAndWait {
            viewContext.zm_sync = syncContext
        }
        syncContext.performAndWait {
            syncContext.zm_userInterface = viewContext
        }
    }

    func configureSyncContext(_ context: NSManagedObjectContext) {
        context.markAsSyncContext()
        context.performAndWait {
            context.createDispatchGroups()
            dispatchGroup.map(context.addGroup(_:))
            context.setupLocalCachedSessionAndSelfUser()

            context.accountDirectoryURL = accountContainer
            context.applicationContainerURL = applicationContainer

            if !DeveloperFlag.proteusViaCoreCrypto.isOn {
                context.setupUserKeyStore(
                    accountDirectory: accountContainer,
                    applicationContainer: applicationContainer
                )
            }

            context.undoManager = nil
            context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)

            FeatureRepository(context: context).createDefaultConfigsIfNeeded()
        }

        // this will be done async, not to block the UI thread, but
        // enqueued on the syncMOC anyway, so it will execute before
        // any other block of code has a chance to use it
        context.performGroupedBlock {
            context.applyPersistedDataPatchesForCurrentVersion()
        }
    }

    func configureSearchContext(_ context: NSManagedObjectContext) {
        context.markAsSearch()
        context.performAndWait {
            context.createDispatchGroups()
            dispatchGroup.map(context.addGroup(_:))
            context.setupLocalCachedSessionAndSelfUser()
            context.undoManager = nil
            context.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
        }
    }

    func configureEventContext(_ context: NSManagedObjectContext) {
        context.performAndWait {
            context.createDispatchGroups()
            dispatchGroup.map(context.addGroup(_:))
        }
    }

    public func linkContexts() {
        syncContext.performGroupedAndWait {
            self.syncContext.zm_userInterface = self.viewContext
        }
        viewContext.zm_sync = syncContext
    }

    // MARK: - Static Helpers

    public static func accountDataFolder(accountIdentifier: UUID, applicationContainer: URL) -> URL {
        applicationContainer
            .appendingPathComponent("AccountData")
            .appendingPathComponent(accountIdentifier.uuidString)
    }

    public static func loadMessagingModel() -> NSManagedObjectModel {
        let modelBundle = Bundle(for: ZMManagedObject.self)

        guard let result = NSManagedObjectModel(
            contentsOf: modelBundle.bundleURL
                .appendingPathComponent("zmessaging.momd")
        ) else {
            fatal("Can't load data model for messaging bundle")
        }

        return result
    }

    public static func loadEventsModel() -> NSManagedObjectModel {
        let modelBundle = WireDataModelBundle.bundle

        guard let result = NSManagedObjectModel(
            contentsOf: modelBundle.bundleURL
                .appendingPathComponent("ZMEventModel.momd")
        ) else {
            fatal("Can't load data model for events bundle")
        }

        return result
    }

    // MARK: - Migration

    public func needsMessagingStoreMigration() -> Bool {
        guard let storeURL = messagesContainer.storeURL else {
            return false
        }
        return messagesMigrator.requiresMigration(at: storeURL, toVersion: .current)
    }

    public func migrateMessagingStore() throws {
        guard let storeURL = messagesContainer.storeURL else {
            throw CoreDataMigratorError.missingStoreURL
        }

        try messagesMigrator.migrateStore(at: storeURL, toVersion: .current)
    }

    public func needsEventStoreMigration() -> Bool {
        guard let storeURL = eventsContainer.storeURL else {
            return false
        }
        return eventsMigrator.requiresMigration(at: storeURL, toVersion: .current)
    }

    public func migrateEventStore() throws {
        guard let storeURL = eventsContainer.storeURL else {
            throw CoreDataMigratorError.missingStoreURL
        }

        try eventsMigrator.migrateStore(at: storeURL, toVersion: .current)
    }
}

// MARK: - PersistentContainer

class PersistentContainer: NSPersistentContainer {
    var storeURL: URL? {
        persistentStoreDescriptions.first?.url
    }

    var storeExists: Bool {
        guard let storeURL else {
            return false
        }

        return FileManager.default.fileExists(atPath: storeURL.path)
    }

    var needsMigration: Bool {
        guard let storeURL, storeExists else {
            return false
        }

        return !managedObjectModel.isConfiguration(
            withName: nil,
            compatibleWithStoreMetadata: metadataForStore(at: storeURL)
        )
    }

    /// Retrieves the metadata for the store
    func metadataForStore(at url: URL) -> [String: Any] {
        guard FileManager.default.fileExists(atPath: url.path),
              let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
                  ofType: NSSQLiteStoreType,
                  at: url
              ) else {
            return [:]
        }

        return metadata
    }
}

// MARK: -

extension NSPersistentStoreCoordinator {
    /// Returns the set of options that need to be passed to the persistent sotre
    static func persistentStoreOptions(supportsMigration: Bool) -> [String: Any] {
        [
            // https://www.sqlite.org/pragma.html
            NSSQLitePragmasOption: [
                "journal_mode": "WAL",
                "synchronous": "FULL",
                "secure_delete": "TRUE",
            ],
            NSMigratePersistentStoresAutomaticallyOption: supportsMigration,
            NSInferMappingModelAutomaticallyOption: supportsMigration,
        ]
    }
}
