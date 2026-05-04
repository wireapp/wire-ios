//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireData
import WireLogging
import WireSystem
import WireUtilities

enum CoreDataStackError: Error {
    case simulateDatabaseLoadingFailure
    case noDatabaseActivity
}

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

@objc(ZMContextProvider)
public protocol ContextProvider {

    var account: Account { get }

    var viewContext: NSManagedObjectContext { get }
    func newBackgroundContext() -> NSManagedObjectContext
    var syncContext: NSManagedObjectContext { get }
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

public extension NSURL {

    /// Returns the location of the persistent store file in the given account folder
    @objc
    func URLByAppendingPersistentStoreLocation() -> URL {
        (self as URL).appendingPersistentStoreLocation()
    }

}

// MARK: -

// sourcery: AutoMockable
public protocol CoreDataStackProtocol: ContextProvider {

    var storesExists: Bool { get }
    var needsMigration: Bool { get }

    func load() async throws

    func setEARMessageEncryptionService(_ service: EARMessageEncryptionServiceProtocol)

}

@objc @objcMembers
public final class CoreDataStack: NSObject, CoreDataStackProtocol, ContextProvider {

    public let account: Account

    public var viewContext: NSManagedObjectContext {
        messagesContainer.viewContext
    }

    private var earMessageEncryptionService: EARMessageEncryptionServiceProtocol?

    public func newBackgroundContext() -> NSManagedObjectContext {
        #if DEBUG
            let context = newBackgroundContextProvider?() ?? messagesContainer.newBackgroundContext()
        #else
            let context = messagesContainer.newBackgroundContext()
        #endif

        // Set the EARMessageEncryptionService on the new background context
        context.performAndWait {
            context.earMessageEncryptionService = earMessageEncryptionService
        }

        return context
    }

    public func setEARMessageEncryptionService(_ service: EARMessageEncryptionServiceProtocol) {
        earMessageEncryptionService = service
    }

    private var _syncContext: NSManagedObjectContext!
    private var _eventContext: NSManagedObjectContext!

    public var syncContext: NSManagedObjectContext {
        _syncContext
    }

    public var eventContext: NSManagedObjectContext {
        _eventContext
    }

    public let accountContainer: URL
    public let applicationContainer: URL

    public let messagesContainer: PersistentContainer
    let eventsContainer: PersistentContainer
    let dispatchGroup: ZMSDispatchGroup?

    #if DEBUG
        public var newBackgroundContextProvider: (() -> NSManagedObjectContext)?
    #endif
    private let messagesMigrator: CoreDataMigrator<CoreDataMessagingMigrationVersion>
    private let eventsMigrator: CoreDataMigrator<CoreDataEventsMigrationVersion>
    private var hasBeenClosed = false

    private let localDomain: String?
    private let isFederationEnabled: Bool

    // MARK: - Initialization

    public init(
        account: Account,
        applicationContainer: URL,
        inMemoryStore: Bool = false,
        dispatchGroup: ZMSDispatchGroup? = nil,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {

        ExtendedSecureUnarchiveFromData.register()

        self.applicationContainer = applicationContainer
        self.account = account
        self.dispatchGroup = dispatchGroup
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled

        let accountDirectory = Self.accountDataFolder(
            accountIdentifier: account.userIdentifier,
            applicationContainer: applicationContainer
        )

        self.accountContainer = accountDirectory

        let eventContainer = PersistentContainer(
            name: "ZMEventModel",
            managedObjectModel: CoreDataStack.loadEventsModel()
        )
        let messagesContainer = PersistentContainer(
            name: "zmessaging",
            managedObjectModel: CoreDataStack.loadMessagingModel()
        )

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

    // MARK: - Close

    public func close() {
        guard !hasBeenClosed  else {
            return
        }

        defer { hasBeenClosed = true }

        viewContext.tearDown()

        // Only tear down contexts if they were initialized
        if _syncContext != nil {
            syncContext.tearDown()
        }
        if _eventContext != nil {
            eventContext.tearDown()
        }

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

    // MARK: - Load

    @MainActor
    public func load() async throws {
        if needsMessagingStoreMigration() {
            try migrateMessagingStore()
        }

        if needsEventStoreMigration() {
            try migrateEventStore()
        }

        try await loadMessagesStore()
        try await loadEventStore()
    }

    func loadMessagesStore() async throws {
        do {
            WireLogger.localStorage.info(
                "loading message store",
                attributes: .safePublic
            )

            try createStoreDirectory(for: messagesContainer)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                messagesContainer.loadPersistentStores { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }

            // Initialize syncContext before configuration
            _syncContext = messagesContainer.newBackgroundContext()

            await configureViewContext(viewContext)
            await configureSyncContext(_syncContext)
            await configureContextReferences()

        } catch {
            WireLogger.localStorage.critical(
                "failed to load message store: \(String(describing: error))",
                attributes: .safePublic
            )
            throw error
        }
    }

    func loadEventStore() async throws {
        do {
            WireLogger.localStorage.info(
                "loading event store",
                attributes: .safePublic
            )

            try createStoreDirectory(for: eventsContainer)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                eventsContainer.loadPersistentStores { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }

            // Initialize eventContext before configuration
            _eventContext = eventsContainer.newBackgroundContext()

            await configureEventContext(_eventContext)

        } catch {
            WireLogger.localStorage.critical(
                "failed to load event store: \(String(describing: error))",
                attributes: .safePublic
            )
            throw error
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

    func configureViewContext(_ context: NSManagedObjectContext) async {
        context.markAsUIContext()
        await context.perform {
            context.localDomain = self.localDomain
            context.isFederationEnabled = self.isFederationEnabled
            context.createDispatchGroups()
            self.dispatchGroup.map(context.addGroup(_:))
            context.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
            ZMUser.selfUser(in: context)
            Label.fetchOrCreateFavoriteLabel(in: context, create: true)
        }
    }

    func configureContextReferences() async {
        await viewContext.perform {
            self.viewContext.zm_sync = self.syncContext
        }
        await syncContext.perform {
            self.syncContext.zm_userInterface = self.viewContext
        }
    }

    func configureSyncContext(_ context: NSManagedObjectContext) async {
        await context.perform {
            // Mark as sync context directly (already on context's queue)
            context.markAsSyncContext()

            context.localDomain = self.localDomain
            context.isFederationEnabled = self.isFederationEnabled
            context.createDispatchGroups()
            self.dispatchGroup.map(context.addGroup(_:))
            context.setupLocalCachedSessionAndSelfUser()

            context.accountDirectoryURL = self.accountContainer
            context.applicationContainerURL = self.applicationContainer

            context.undoManager = nil
            context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)

            LegacyFeatureRepository(context: context).createDefaultConfigsIfNeeded()
        }
    }

    func configureEventContext(_ context: NSManagedObjectContext) async {
        await context.perform {
            context.createDispatchGroups()
            self.dispatchGroup.map(context.addGroup(_:))
        }
    }

    // MARK: - Static Helpers

    public static func accountDataFolder(accountIdentifier: UUID, applicationContainer: URL) -> URL {
        applicationContainer
            .appendingPathComponent("AccountData")
            .appendingPathComponent(accountIdentifier.uuidString)
    }

    public static func loadMessagingModel() -> NSManagedObjectModel {
        let modelBundle = WireDataBundle.bundle

        guard let result = NSManagedObjectModel(
            contentsOf: modelBundle.bundleURL
                .appendingPathComponent("zmessaging.momd")
        ) else {
            fatal("Can't load data model for messaging bundle")
        }

        return result
    }

    public static func loadEventsModel() -> NSManagedObjectModel {
        let modelBundle = WireDataBundle.bundle

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
        guard let storeURL = messagesContainer.storeURL else { return false }
        return messagesMigrator.requiresMigration(at: storeURL, toVersion: .current)
    }

    public func migrateMessagingStore() throws {
        WireLogger.localStorage.info(
            "migrating messaging store",
            attributes: .safePublic
        )

        let startDate = Date()

        guard let storeURL = messagesContainer.storeURL else {
            WireLogger.localStorage.critical(
                "failed to migrate messaging store: missing store URL",
                attributes: .safePublic
            )
            throw CoreDataMigratorError.missingStoreURL
        }

        do {
            try messagesMigrator.migrateStore(at: storeURL, toVersion: .current)
            let duration = (startDate ..< .now).formatted(
                Date.ComponentsFormatStyle(style: .narrow)
            )
            WireLogger.localStorage.info(
                "message store migration completed in \(duration)",
                attributes: .safePublic
            )
        } catch {
            WireLogger.localStorage.critical(
                "failed to migrate messaging store: \(String(describing: error))",
                attributes: .safePublic
            )
            throw error
        }
    }

    public func needsEventStoreMigration() -> Bool {
        guard let storeURL = eventsContainer.storeURL else { return false }
        return eventsMigrator.requiresMigration(at: storeURL, toVersion: .current)
    }

    public func migrateEventStore() throws {
        WireLogger.localStorage.info(
            "migrating event store",
            attributes: .safePublic
        )

        let startDate = Date()

        guard let storeURL = eventsContainer.storeURL else {
            WireLogger.localStorage.critical(
                "failed to migrate event store: missing store URL",
                attributes: .safePublic
            )
            throw CoreDataMigratorError.missingStoreURL
        }

        do {
            try eventsMigrator.migrateStore(at: storeURL, toVersion: .current)
            let duration = (startDate ..< .now).formatted(
                Date.ComponentsFormatStyle(style: .narrow)
            )
            WireLogger.localStorage.info(
                "event store migration completed in \(duration)",
                attributes: .safePublic
            )
        } catch {
            WireLogger.localStorage.critical(
                "failed to migrate event store: \(String(describing: error))",
                attributes: .safePublic
            )
            throw error
        }
    }

}

// MARK: -

public class PersistentContainer: NSPersistentContainer {

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
                "secure_delete": "TRUE"
            ],
            NSMigratePersistentStoresAutomaticallyOption: supportsMigration,
            NSInferMappingModelAutomaticallyOption: supportsMigration
        ]
    }

}
