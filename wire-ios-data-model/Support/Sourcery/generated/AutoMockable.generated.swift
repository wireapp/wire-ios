// Generated using Sourcery 2.1.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import LocalAuthentication
import Combine

@testable import WireDataModel





















public class MockConversationEventProcessorProtocol: ConversationEventProcessorProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - processConversationEvents

    public var processConversationEvents_Invocations: [[ZMUpdateEvent]] = []
    public var processConversationEvents_MockMethod: (([ZMUpdateEvent]) async -> Void)?

    public func processConversationEvents(_ events: [ZMUpdateEvent]) async {
        processConversationEvents_Invocations.append(events)

        guard let mock = processConversationEvents_MockMethod else {
            fatalError("no mock for `processConversationEvents`")
        }

        await mock(events)
    }

    // MARK: - processPayload

    public var processPayload_Invocations: [ZMTransportData] = []
    public var processPayload_MockMethod: ((ZMTransportData) -> Void)?

    public func processPayload(_ payload: ZMTransportData) {
        processPayload_Invocations.append(payload)

        guard let mock = processPayload_MockMethod else {
            fatalError("no mock for `processPayload`")
        }

        mock(payload)
    }

}

public class MockCoreCryptoProviderProtocol: CoreCryptoProviderProtocol {

    // MARK: - Life cycle

    public init() {}


    // MARK: - coreCrypto

    public var coreCryptoRequireMLS_Invocations: [Bool] = []
    public var coreCryptoRequireMLS_MockError: Error?
    public var coreCryptoRequireMLS_MockMethod: ((Bool) throws -> SafeCoreCryptoProtocol)?
    public var coreCryptoRequireMLS_MockValue: SafeCoreCryptoProtocol?

    public func coreCrypto(requireMLS: Bool) throws -> SafeCoreCryptoProtocol {
        coreCryptoRequireMLS_Invocations.append(requireMLS)

        if let error = coreCryptoRequireMLS_MockError {
            throw error
        }

        if let mock = coreCryptoRequireMLS_MockMethod {
            return try mock(requireMLS)
        } else if let mock = coreCryptoRequireMLS_MockValue {
            return mock
        } else {
            fatalError("no mock for `coreCryptoRequireMLS`")
        }
    }

}

class MockCoreDataMessagingMigratorProtocol: CoreDataMessagingMigratorProtocol {

    // MARK: - Life cycle



    // MARK: - requiresMigration

    var requiresMigrationAtToVersion_Invocations: [(storeURL: URL, version: CoreDataMessagingMigrationVersion)] = []
    var requiresMigrationAtToVersion_MockMethod: ((URL, CoreDataMessagingMigrationVersion) -> Bool)?
    var requiresMigrationAtToVersion_MockValue: Bool?

    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) -> Bool {
        requiresMigrationAtToVersion_Invocations.append((storeURL: storeURL, version: version))

        if let mock = requiresMigrationAtToVersion_MockMethod {
            return mock(storeURL, version)
        } else if let mock = requiresMigrationAtToVersion_MockValue {
            return mock
        } else {
            fatalError("no mock for `requiresMigrationAtToVersion`")
        }
    }

    // MARK: - migrateStore

    var migrateStoreAtToVersion_Invocations: [(storeURL: URL, version: CoreDataMessagingMigrationVersion)] = []
    var migrateStoreAtToVersion_MockError: Error?
    var migrateStoreAtToVersion_MockMethod: ((URL, CoreDataMessagingMigrationVersion) throws -> Void)?

    func migrateStore(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) throws {
        migrateStoreAtToVersion_Invocations.append((storeURL: storeURL, version: version))

        if let error = migrateStoreAtToVersion_MockError {
            throw error
        }

        guard let mock = migrateStoreAtToVersion_MockMethod else {
            fatalError("no mock for `migrateStoreAtToVersion`")
        }

        try mock(storeURL, version)
    }

}

public class MockCryptoboxMigrationManagerInterface: CryptoboxMigrationManagerInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - isMigrationNeeded

    public var isMigrationNeededAccountDirectory_Invocations: [URL] = []
    public var isMigrationNeededAccountDirectory_MockMethod: ((URL) -> Bool)?
    public var isMigrationNeededAccountDirectory_MockValue: Bool?

    public func isMigrationNeeded(accountDirectory: URL) -> Bool {
        isMigrationNeededAccountDirectory_Invocations.append(accountDirectory)

        if let mock = isMigrationNeededAccountDirectory_MockMethod {
            return mock(accountDirectory)
        } else if let mock = isMigrationNeededAccountDirectory_MockValue {
            return mock
        } else {
            fatalError("no mock for `isMigrationNeededAccountDirectory`")
        }
    }

    // MARK: - performMigration

    public var performMigrationAccountDirectoryCoreCrypto_Invocations: [(accountDirectory: URL, coreCrypto: SafeCoreCryptoProtocol)] = []
    public var performMigrationAccountDirectoryCoreCrypto_MockError: Error?
    public var performMigrationAccountDirectoryCoreCrypto_MockMethod: ((URL, SafeCoreCryptoProtocol) throws -> Void)?

    public func performMigration(accountDirectory: URL, coreCrypto: SafeCoreCryptoProtocol) throws {
        performMigrationAccountDirectoryCoreCrypto_Invocations.append((accountDirectory: accountDirectory, coreCrypto: coreCrypto))

        if let error = performMigrationAccountDirectoryCoreCrypto_MockError {
            throw error
        }

        guard let mock = performMigrationAccountDirectoryCoreCrypto_MockMethod else {
            fatalError("no mock for `performMigrationAccountDirectoryCoreCrypto`")
        }

        try mock(accountDirectory, coreCrypto)
    }

}

class MockEARKeyEncryptorInterface: EARKeyEncryptorInterface {

    // MARK: - Life cycle



    // MARK: - encryptDatabaseKey

    var encryptDatabaseKeyPublicKey_Invocations: [(databaseKey: Data, publicKey: SecKey)] = []
    var encryptDatabaseKeyPublicKey_MockError: Error?
    var encryptDatabaseKeyPublicKey_MockMethod: ((Data, SecKey) throws -> Data)?
    var encryptDatabaseKeyPublicKey_MockValue: Data?

    func encryptDatabaseKey(_ databaseKey: Data, publicKey: SecKey) throws -> Data {
        encryptDatabaseKeyPublicKey_Invocations.append((databaseKey: databaseKey, publicKey: publicKey))

        if let error = encryptDatabaseKeyPublicKey_MockError {
            throw error
        }

        if let mock = encryptDatabaseKeyPublicKey_MockMethod {
            return try mock(databaseKey, publicKey)
        } else if let mock = encryptDatabaseKeyPublicKey_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptDatabaseKeyPublicKey`")
        }
    }

    // MARK: - decryptDatabaseKey

    var decryptDatabaseKeyPrivateKey_Invocations: [(encryptedDatabaseKey: Data, privateKey: SecKey)] = []
    var decryptDatabaseKeyPrivateKey_MockError: Error?
    var decryptDatabaseKeyPrivateKey_MockMethod: ((Data, SecKey) throws -> Data)?
    var decryptDatabaseKeyPrivateKey_MockValue: Data?

    func decryptDatabaseKey(_ encryptedDatabaseKey: Data, privateKey: SecKey) throws -> Data {
        decryptDatabaseKeyPrivateKey_Invocations.append((encryptedDatabaseKey: encryptedDatabaseKey, privateKey: privateKey))

        if let error = decryptDatabaseKeyPrivateKey_MockError {
            throw error
        }

        if let mock = decryptDatabaseKeyPrivateKey_MockMethod {
            return try mock(encryptedDatabaseKey, privateKey)
        } else if let mock = decryptDatabaseKeyPrivateKey_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptDatabaseKeyPrivateKey`")
        }
    }

}

public class MockEARKeyRepositoryInterface: EARKeyRepositoryInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - storePublicKey

    public var storePublicKeyDescriptionKey_Invocations: [(description: PublicEARKeyDescription, key: SecKey)] = []
    public var storePublicKeyDescriptionKey_MockError: Error?
    public var storePublicKeyDescriptionKey_MockMethod: ((PublicEARKeyDescription, SecKey) throws -> Void)?

    public func storePublicKey(description: PublicEARKeyDescription, key: SecKey) throws {
        storePublicKeyDescriptionKey_Invocations.append((description: description, key: key))

        if let error = storePublicKeyDescriptionKey_MockError {
            throw error
        }

        guard let mock = storePublicKeyDescriptionKey_MockMethod else {
            fatalError("no mock for `storePublicKeyDescriptionKey`")
        }

        try mock(description, key)
    }

    // MARK: - fetchPublicKey

    public var fetchPublicKeyDescription_Invocations: [PublicEARKeyDescription] = []
    public var fetchPublicKeyDescription_MockError: Error?
    public var fetchPublicKeyDescription_MockMethod: ((PublicEARKeyDescription) throws -> SecKey)?
    public var fetchPublicKeyDescription_MockValue: SecKey?

    public func fetchPublicKey(description: PublicEARKeyDescription) throws -> SecKey {
        fetchPublicKeyDescription_Invocations.append(description)

        if let error = fetchPublicKeyDescription_MockError {
            throw error
        }

        if let mock = fetchPublicKeyDescription_MockMethod {
            return try mock(description)
        } else if let mock = fetchPublicKeyDescription_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPublicKeyDescription`")
        }
    }

    // MARK: - deletePublicKey

    public var deletePublicKeyDescription_Invocations: [PublicEARKeyDescription] = []
    public var deletePublicKeyDescription_MockError: Error?
    public var deletePublicKeyDescription_MockMethod: ((PublicEARKeyDescription) throws -> Void)?

    public func deletePublicKey(description: PublicEARKeyDescription) throws {
        deletePublicKeyDescription_Invocations.append(description)

        if let error = deletePublicKeyDescription_MockError {
            throw error
        }

        guard let mock = deletePublicKeyDescription_MockMethod else {
            fatalError("no mock for `deletePublicKeyDescription`")
        }

        try mock(description)
    }

    // MARK: - fetchPrivateKey

    public var fetchPrivateKeyDescription_Invocations: [PrivateEARKeyDescription] = []
    public var fetchPrivateKeyDescription_MockError: Error?
    public var fetchPrivateKeyDescription_MockMethod: ((PrivateEARKeyDescription) throws -> SecKey)?
    public var fetchPrivateKeyDescription_MockValue: SecKey?

    public func fetchPrivateKey(description: PrivateEARKeyDescription) throws -> SecKey {
        fetchPrivateKeyDescription_Invocations.append(description)

        if let error = fetchPrivateKeyDescription_MockError {
            throw error
        }

        if let mock = fetchPrivateKeyDescription_MockMethod {
            return try mock(description)
        } else if let mock = fetchPrivateKeyDescription_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPrivateKeyDescription`")
        }
    }

    // MARK: - deletePrivateKey

    public var deletePrivateKeyDescription_Invocations: [PrivateEARKeyDescription] = []
    public var deletePrivateKeyDescription_MockError: Error?
    public var deletePrivateKeyDescription_MockMethod: ((PrivateEARKeyDescription) throws -> Void)?

    public func deletePrivateKey(description: PrivateEARKeyDescription) throws {
        deletePrivateKeyDescription_Invocations.append(description)

        if let error = deletePrivateKeyDescription_MockError {
            throw error
        }

        guard let mock = deletePrivateKeyDescription_MockMethod else {
            fatalError("no mock for `deletePrivateKeyDescription`")
        }

        try mock(description)
    }

    // MARK: - storeDatabaseKey

    public var storeDatabaseKeyDescriptionKey_Invocations: [(description: DatabaseEARKeyDescription, key: Data)] = []
    public var storeDatabaseKeyDescriptionKey_MockError: Error?
    public var storeDatabaseKeyDescriptionKey_MockMethod: ((DatabaseEARKeyDescription, Data) throws -> Void)?

    public func storeDatabaseKey(description: DatabaseEARKeyDescription, key: Data) throws {
        storeDatabaseKeyDescriptionKey_Invocations.append((description: description, key: key))

        if let error = storeDatabaseKeyDescriptionKey_MockError {
            throw error
        }

        guard let mock = storeDatabaseKeyDescriptionKey_MockMethod else {
            fatalError("no mock for `storeDatabaseKeyDescriptionKey`")
        }

        try mock(description, key)
    }

    // MARK: - fetchDatabaseKey

    public var fetchDatabaseKeyDescription_Invocations: [DatabaseEARKeyDescription] = []
    public var fetchDatabaseKeyDescription_MockError: Error?
    public var fetchDatabaseKeyDescription_MockMethod: ((DatabaseEARKeyDescription) throws -> Data)?
    public var fetchDatabaseKeyDescription_MockValue: Data?

    public func fetchDatabaseKey(description: DatabaseEARKeyDescription) throws -> Data {
        fetchDatabaseKeyDescription_Invocations.append(description)

        if let error = fetchDatabaseKeyDescription_MockError {
            throw error
        }

        if let mock = fetchDatabaseKeyDescription_MockMethod {
            return try mock(description)
        } else if let mock = fetchDatabaseKeyDescription_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchDatabaseKeyDescription`")
        }
    }

    // MARK: - deleteDatabaseKey

    public var deleteDatabaseKeyDescription_Invocations: [DatabaseEARKeyDescription] = []
    public var deleteDatabaseKeyDescription_MockError: Error?
    public var deleteDatabaseKeyDescription_MockMethod: ((DatabaseEARKeyDescription) throws -> Void)?

    public func deleteDatabaseKey(description: DatabaseEARKeyDescription) throws {
        deleteDatabaseKeyDescription_Invocations.append(description)

        if let error = deleteDatabaseKeyDescription_MockError {
            throw error
        }

        guard let mock = deleteDatabaseKeyDescription_MockMethod else {
            fatalError("no mock for `deleteDatabaseKeyDescription`")
        }

        try mock(description)
    }

    // MARK: - clearCache

    public var clearCache_Invocations: [Void] = []
    public var clearCache_MockMethod: (() -> Void)?

    public func clearCache() {
        clearCache_Invocations.append(())

        guard let mock = clearCache_MockMethod else {
            fatalError("no mock for `clearCache`")
        }

        mock()
    }

}

public class MockEARServiceInterface: EARServiceInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - delegate

    public var delegate: EARServiceDelegate?


    // MARK: - enableEncryptionAtRest

    public var enableEncryptionAtRestContextSkipMigration_Invocations: [(context: NSManagedObjectContext, skipMigration: Bool)] = []
    public var enableEncryptionAtRestContextSkipMigration_MockError: Error?
    public var enableEncryptionAtRestContextSkipMigration_MockMethod: ((NSManagedObjectContext, Bool) throws -> Void)?

    public func enableEncryptionAtRest(context: NSManagedObjectContext, skipMigration: Bool) throws {
        enableEncryptionAtRestContextSkipMigration_Invocations.append((context: context, skipMigration: skipMigration))

        if let error = enableEncryptionAtRestContextSkipMigration_MockError {
            throw error
        }

        guard let mock = enableEncryptionAtRestContextSkipMigration_MockMethod else {
            fatalError("no mock for `enableEncryptionAtRestContextSkipMigration`")
        }

        try mock(context, skipMigration)
    }

    // MARK: - disableEncryptionAtRest

    public var disableEncryptionAtRestContextSkipMigration_Invocations: [(context: NSManagedObjectContext, skipMigration: Bool)] = []
    public var disableEncryptionAtRestContextSkipMigration_MockError: Error?
    public var disableEncryptionAtRestContextSkipMigration_MockMethod: ((NSManagedObjectContext, Bool) throws -> Void)?

    public func disableEncryptionAtRest(context: NSManagedObjectContext, skipMigration: Bool) throws {
        disableEncryptionAtRestContextSkipMigration_Invocations.append((context: context, skipMigration: skipMigration))

        if let error = disableEncryptionAtRestContextSkipMigration_MockError {
            throw error
        }

        guard let mock = disableEncryptionAtRestContextSkipMigration_MockMethod else {
            fatalError("no mock for `disableEncryptionAtRestContextSkipMigration`")
        }

        try mock(context, skipMigration)
    }

    // MARK: - lockDatabase

    public var lockDatabase_Invocations: [Void] = []
    public var lockDatabase_MockMethod: (() -> Void)?

    public func lockDatabase() {
        lockDatabase_Invocations.append(())

        guard let mock = lockDatabase_MockMethod else {
            fatalError("no mock for `lockDatabase`")
        }

        mock()
    }

    // MARK: - unlockDatabase

    public var unlockDatabaseContext_Invocations: [LAContext] = []
    public var unlockDatabaseContext_MockError: Error?
    public var unlockDatabaseContext_MockMethod: ((LAContext) throws -> Void)?

    public func unlockDatabase(context: LAContext) throws {
        unlockDatabaseContext_Invocations.append(context)

        if let error = unlockDatabaseContext_MockError {
            throw error
        }

        guard let mock = unlockDatabaseContext_MockMethod else {
            fatalError("no mock for `unlockDatabaseContext`")
        }

        try mock(context)
    }

    // MARK: - fetchPublicKeys

    public var fetchPublicKeys_Invocations: [Void] = []
    public var fetchPublicKeys_MockError: Error?
    public var fetchPublicKeys_MockMethod: (() throws -> EARPublicKeys?)?
    public var fetchPublicKeys_MockValue: EARPublicKeys??

    public func fetchPublicKeys() throws -> EARPublicKeys? {
        fetchPublicKeys_Invocations.append(())

        if let error = fetchPublicKeys_MockError {
            throw error
        }

        if let mock = fetchPublicKeys_MockMethod {
            return try mock()
        } else if let mock = fetchPublicKeys_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPublicKeys`")
        }
    }

    // MARK: - fetchPrivateKeys

    public var fetchPrivateKeysIncludingPrimary_Invocations: [Bool] = []
    public var fetchPrivateKeysIncludingPrimary_MockError: Error?
    public var fetchPrivateKeysIncludingPrimary_MockMethod: ((Bool) throws -> EARPrivateKeys?)?
    public var fetchPrivateKeysIncludingPrimary_MockValue: EARPrivateKeys??

    public func fetchPrivateKeys(includingPrimary: Bool) throws -> EARPrivateKeys? {
        fetchPrivateKeysIncludingPrimary_Invocations.append(includingPrimary)

        if let error = fetchPrivateKeysIncludingPrimary_MockError {
            throw error
        }

        if let mock = fetchPrivateKeysIncludingPrimary_MockMethod {
            return try mock(includingPrimary)
        } else if let mock = fetchPrivateKeysIncludingPrimary_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPrivateKeysIncludingPrimary`")
        }
    }

    // MARK: - setInitialEARFlagValue

    public var setInitialEARFlagValue_Invocations: [Bool] = []
    public var setInitialEARFlagValue_MockMethod: ((Bool) -> Void)?

    public func setInitialEARFlagValue(_ enabled: Bool) {
        setInitialEARFlagValue_Invocations.append(enabled)

        guard let mock = setInitialEARFlagValue_MockMethod else {
            fatalError("no mock for `setInitialEARFlagValue`")
        }

        mock(enabled)
    }

}

public class MockFeatureRepositoryInterface: FeatureRepositoryInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchAppLock

    public var fetchAppLock_Invocations: [Void] = []
    public var fetchAppLock_MockMethod: (() -> Feature.AppLock)?
    public var fetchAppLock_MockValue: Feature.AppLock?

    public func fetchAppLock() -> Feature.AppLock {
        fetchAppLock_Invocations.append(())

        if let mock = fetchAppLock_MockMethod {
            return mock()
        } else if let mock = fetchAppLock_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchAppLock`")
        }
    }

    // MARK: - storeAppLock

    public var storeAppLock_Invocations: [Feature.AppLock] = []
    public var storeAppLock_MockMethod: ((Feature.AppLock) -> Void)?

    public func storeAppLock(_ appLock: Feature.AppLock) {
        storeAppLock_Invocations.append(appLock)

        guard let mock = storeAppLock_MockMethod else {
            fatalError("no mock for `storeAppLock`")
        }

        mock(appLock)
    }

    // MARK: - fetchConferenceCalling

    public var fetchConferenceCalling_Invocations: [Void] = []
    public var fetchConferenceCalling_MockMethod: (() -> Feature.ConferenceCalling)?
    public var fetchConferenceCalling_MockValue: Feature.ConferenceCalling?

    public func fetchConferenceCalling() -> Feature.ConferenceCalling {
        fetchConferenceCalling_Invocations.append(())

        if let mock = fetchConferenceCalling_MockMethod {
            return mock()
        } else if let mock = fetchConferenceCalling_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConferenceCalling`")
        }
    }

    // MARK: - storeConferenceCalling

    public var storeConferenceCalling_Invocations: [Feature.ConferenceCalling] = []
    public var storeConferenceCalling_MockMethod: ((Feature.ConferenceCalling) -> Void)?

    public func storeConferenceCalling(_ conferenceCalling: Feature.ConferenceCalling) {
        storeConferenceCalling_Invocations.append(conferenceCalling)

        guard let mock = storeConferenceCalling_MockMethod else {
            fatalError("no mock for `storeConferenceCalling`")
        }

        mock(conferenceCalling)
    }

    // MARK: - fetchFileSharing

    public var fetchFileSharing_Invocations: [Void] = []
    public var fetchFileSharing_MockMethod: (() -> Feature.FileSharing)?
    public var fetchFileSharing_MockValue: Feature.FileSharing?

    public func fetchFileSharing() -> Feature.FileSharing {
        fetchFileSharing_Invocations.append(())

        if let mock = fetchFileSharing_MockMethod {
            return mock()
        } else if let mock = fetchFileSharing_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchFileSharing`")
        }
    }

    // MARK: - storeFileSharing

    public var storeFileSharing_Invocations: [Feature.FileSharing] = []
    public var storeFileSharing_MockMethod: ((Feature.FileSharing) -> Void)?

    public func storeFileSharing(_ fileSharing: Feature.FileSharing) {
        storeFileSharing_Invocations.append(fileSharing)

        guard let mock = storeFileSharing_MockMethod else {
            fatalError("no mock for `storeFileSharing`")
        }

        mock(fileSharing)
    }

    // MARK: - fetchSelfDeletingMesssages

    public var fetchSelfDeletingMesssages_Invocations: [Void] = []
    public var fetchSelfDeletingMesssages_MockMethod: (() -> Feature.SelfDeletingMessages)?
    public var fetchSelfDeletingMesssages_MockValue: Feature.SelfDeletingMessages?

    public func fetchSelfDeletingMesssages() -> Feature.SelfDeletingMessages {
        fetchSelfDeletingMesssages_Invocations.append(())

        if let mock = fetchSelfDeletingMesssages_MockMethod {
            return mock()
        } else if let mock = fetchSelfDeletingMesssages_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfDeletingMesssages`")
        }
    }

    // MARK: - storeSelfDeletingMessages

    public var storeSelfDeletingMessages_Invocations: [Feature.SelfDeletingMessages] = []
    public var storeSelfDeletingMessages_MockMethod: ((Feature.SelfDeletingMessages) -> Void)?

    public func storeSelfDeletingMessages(_ selfDeletingMessages: Feature.SelfDeletingMessages) {
        storeSelfDeletingMessages_Invocations.append(selfDeletingMessages)

        guard let mock = storeSelfDeletingMessages_MockMethod else {
            fatalError("no mock for `storeSelfDeletingMessages`")
        }

        mock(selfDeletingMessages)
    }

    // MARK: - fetchConversationGuestLinks

    public var fetchConversationGuestLinks_Invocations: [Void] = []
    public var fetchConversationGuestLinks_MockMethod: (() -> Feature.ConversationGuestLinks)?
    public var fetchConversationGuestLinks_MockValue: Feature.ConversationGuestLinks?

    public func fetchConversationGuestLinks() -> Feature.ConversationGuestLinks {
        fetchConversationGuestLinks_Invocations.append(())

        if let mock = fetchConversationGuestLinks_MockMethod {
            return mock()
        } else if let mock = fetchConversationGuestLinks_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConversationGuestLinks`")
        }
    }

    // MARK: - storeConversationGuestLinks

    public var storeConversationGuestLinks_Invocations: [Feature.ConversationGuestLinks] = []
    public var storeConversationGuestLinks_MockMethod: ((Feature.ConversationGuestLinks) -> Void)?

    public func storeConversationGuestLinks(_ conversationGuestLinks: Feature.ConversationGuestLinks) {
        storeConversationGuestLinks_Invocations.append(conversationGuestLinks)

        guard let mock = storeConversationGuestLinks_MockMethod else {
            fatalError("no mock for `storeConversationGuestLinks`")
        }

        mock(conversationGuestLinks)
    }

    // MARK: - fetchClassifiedDomains

    public var fetchClassifiedDomains_Invocations: [Void] = []
    public var fetchClassifiedDomains_MockMethod: (() -> Feature.ClassifiedDomains)?
    public var fetchClassifiedDomains_MockValue: Feature.ClassifiedDomains?

    public func fetchClassifiedDomains() -> Feature.ClassifiedDomains {
        fetchClassifiedDomains_Invocations.append(())

        if let mock = fetchClassifiedDomains_MockMethod {
            return mock()
        } else if let mock = fetchClassifiedDomains_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchClassifiedDomains`")
        }
    }

    // MARK: - storeClassifiedDomains

    public var storeClassifiedDomains_Invocations: [Feature.ClassifiedDomains] = []
    public var storeClassifiedDomains_MockMethod: ((Feature.ClassifiedDomains) -> Void)?

    public func storeClassifiedDomains(_ classifiedDomains: Feature.ClassifiedDomains) {
        storeClassifiedDomains_Invocations.append(classifiedDomains)

        guard let mock = storeClassifiedDomains_MockMethod else {
            fatalError("no mock for `storeClassifiedDomains`")
        }

        mock(classifiedDomains)
    }

    // MARK: - fetchDigitalSignature

    public var fetchDigitalSignature_Invocations: [Void] = []
    public var fetchDigitalSignature_MockMethod: (() -> Feature.DigitalSignature)?
    public var fetchDigitalSignature_MockValue: Feature.DigitalSignature?

    public func fetchDigitalSignature() -> Feature.DigitalSignature {
        fetchDigitalSignature_Invocations.append(())

        if let mock = fetchDigitalSignature_MockMethod {
            return mock()
        } else if let mock = fetchDigitalSignature_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchDigitalSignature`")
        }
    }

    // MARK: - storeDigitalSignature

    public var storeDigitalSignature_Invocations: [Feature.DigitalSignature] = []
    public var storeDigitalSignature_MockMethod: ((Feature.DigitalSignature) -> Void)?

    public func storeDigitalSignature(_ digitalSignature: Feature.DigitalSignature) {
        storeDigitalSignature_Invocations.append(digitalSignature)

        guard let mock = storeDigitalSignature_MockMethod else {
            fatalError("no mock for `storeDigitalSignature`")
        }

        mock(digitalSignature)
    }

    // MARK: - fetchMLS

    public var fetchMLS_Invocations: [Void] = []
    public var fetchMLS_MockMethod: (() -> Feature.MLS)?
    public var fetchMLS_MockValue: Feature.MLS?

    public func fetchMLS() -> Feature.MLS {
        fetchMLS_Invocations.append(())

        if let mock = fetchMLS_MockMethod {
            return mock()
        } else if let mock = fetchMLS_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchMLS`")
        }
    }

    // MARK: - storeMLS

    public var storeMLS_Invocations: [Feature.MLS] = []
    public var storeMLS_MockMethod: ((Feature.MLS) -> Void)?

    public func storeMLS(_ mls: Feature.MLS) {
        storeMLS_Invocations.append(mls)

        guard let mock = storeMLS_MockMethod else {
            fatalError("no mock for `storeMLS`")
        }

        mock(mls)
    }

}

class MockFileManagerInterface: FileManagerInterface {

    // MARK: - Life cycle



    // MARK: - fileExists

    var fileExistsAtPath_Invocations: [String] = []
    var fileExistsAtPath_MockMethod: ((String) -> Bool)?
    var fileExistsAtPath_MockValue: Bool?

    func fileExists(atPath path: String) -> Bool {
        fileExistsAtPath_Invocations.append(path)

        if let mock = fileExistsAtPath_MockMethod {
            return mock(path)
        } else if let mock = fileExistsAtPath_MockValue {
            return mock
        } else {
            fatalError("no mock for `fileExistsAtPath`")
        }
    }

    // MARK: - removeItem

    var removeItemAt_Invocations: [URL] = []
    var removeItemAt_MockError: Error?
    var removeItemAt_MockMethod: ((URL) throws -> Void)?

    func removeItem(at url: URL) throws {
        removeItemAt_Invocations.append(url)

        if let error = removeItemAt_MockError {
            throw error
        }

        guard let mock = removeItemAt_MockMethod else {
            fatalError("no mock for `removeItemAt`")
        }

        try mock(url)
    }

    // MARK: - cryptoboxDirectory

    var cryptoboxDirectoryIn_Invocations: [URL] = []
    var cryptoboxDirectoryIn_MockMethod: ((URL) -> URL)?
    var cryptoboxDirectoryIn_MockValue: URL?

    func cryptoboxDirectory(in accountDirectory: URL) -> URL {
        cryptoboxDirectoryIn_Invocations.append(accountDirectory)

        if let mock = cryptoboxDirectoryIn_MockMethod {
            return mock(accountDirectory)
        } else if let mock = cryptoboxDirectoryIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `cryptoboxDirectoryIn`")
        }
    }

}

class MockMLSActionsProviderProtocol: MLSActionsProviderProtocol {

    // MARK: - Life cycle



    // MARK: - fetchBackendPublicKeys

    var fetchBackendPublicKeysIn_Invocations: [NotificationContext] = []
    var fetchBackendPublicKeysIn_MockError: Error?
    var fetchBackendPublicKeysIn_MockMethod: ((NotificationContext) async throws -> BackendMLSPublicKeys)?
    var fetchBackendPublicKeysIn_MockValue: BackendMLSPublicKeys?

    func fetchBackendPublicKeys(in context: NotificationContext) async throws -> BackendMLSPublicKeys {
        fetchBackendPublicKeysIn_Invocations.append(context)

        if let error = fetchBackendPublicKeysIn_MockError {
            throw error
        }

        if let mock = fetchBackendPublicKeysIn_MockMethod {
            return try await mock(context)
        } else if let mock = fetchBackendPublicKeysIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchBackendPublicKeysIn`")
        }
    }

    // MARK: - countUnclaimedKeyPackages

    var countUnclaimedKeyPackagesClientIDContext_Invocations: [(clientID: String, context: NotificationContext)] = []
    var countUnclaimedKeyPackagesClientIDContext_MockError: Error?
    var countUnclaimedKeyPackagesClientIDContext_MockMethod: ((String, NotificationContext) async throws -> Int)?
    var countUnclaimedKeyPackagesClientIDContext_MockValue: Int?

    func countUnclaimedKeyPackages(clientID: String, context: NotificationContext) async throws -> Int {
        countUnclaimedKeyPackagesClientIDContext_Invocations.append((clientID: clientID, context: context))

        if let error = countUnclaimedKeyPackagesClientIDContext_MockError {
            throw error
        }

        if let mock = countUnclaimedKeyPackagesClientIDContext_MockMethod {
            return try await mock(clientID, context)
        } else if let mock = countUnclaimedKeyPackagesClientIDContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `countUnclaimedKeyPackagesClientIDContext`")
        }
    }

    // MARK: - uploadKeyPackages

    var uploadKeyPackagesClientIDKeyPackagesContext_Invocations: [(clientID: String, keyPackages: [String], context: NotificationContext)] = []
    var uploadKeyPackagesClientIDKeyPackagesContext_MockError: Error?
    var uploadKeyPackagesClientIDKeyPackagesContext_MockMethod: ((String, [String], NotificationContext) async throws -> Void)?

    func uploadKeyPackages(clientID: String, keyPackages: [String], context: NotificationContext) async throws {
        uploadKeyPackagesClientIDKeyPackagesContext_Invocations.append((clientID: clientID, keyPackages: keyPackages, context: context))

        if let error = uploadKeyPackagesClientIDKeyPackagesContext_MockError {
            throw error
        }

        guard let mock = uploadKeyPackagesClientIDKeyPackagesContext_MockMethod else {
            fatalError("no mock for `uploadKeyPackagesClientIDKeyPackagesContext`")
        }

        try await mock(clientID, keyPackages, context)
    }

    // MARK: - claimKeyPackages

    var claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_Invocations: [(userID: UUID, domain: String?, excludedSelfClientID: String?, context: NotificationContext)] = []
    var claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockError: Error?
    var claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockMethod: ((UUID, String?, String?, NotificationContext) async throws -> [KeyPackage])?
    var claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockValue: [KeyPackage]?

    func claimKeyPackages(userID: UUID, domain: String?, excludedSelfClientID: String?, in context: NotificationContext) async throws -> [KeyPackage] {
        claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_Invocations.append((userID: userID, domain: domain, excludedSelfClientID: excludedSelfClientID, context: context))

        if let error = claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockError {
            throw error
        }

        if let mock = claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockMethod {
            return try await mock(userID, domain, excludedSelfClientID, context)
        } else if let mock = claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `claimKeyPackagesUserIDDomainExcludedSelfClientIDIn`")
        }
    }

    // MARK: - sendMessage

    var sendMessageIn_Invocations: [(message: Data, context: NotificationContext)] = []
    var sendMessageIn_MockError: Error?
    var sendMessageIn_MockMethod: ((Data, NotificationContext) async throws -> [ZMUpdateEvent])?
    var sendMessageIn_MockValue: [ZMUpdateEvent]?

    func sendMessage(_ message: Data, in context: NotificationContext) async throws -> [ZMUpdateEvent] {
        sendMessageIn_Invocations.append((message: message, context: context))

        if let error = sendMessageIn_MockError {
            throw error
        }

        if let mock = sendMessageIn_MockMethod {
            return try await mock(message, context)
        } else if let mock = sendMessageIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendMessageIn`")
        }
    }

    // MARK: - sendCommitBundle

    var sendCommitBundleIn_Invocations: [(bundle: Data, context: NotificationContext)] = []
    var sendCommitBundleIn_MockError: Error?
    var sendCommitBundleIn_MockMethod: ((Data, NotificationContext) async throws -> [ZMUpdateEvent])?
    var sendCommitBundleIn_MockValue: [ZMUpdateEvent]?

    func sendCommitBundle(_ bundle: Data, in context: NotificationContext) async throws -> [ZMUpdateEvent] {
        sendCommitBundleIn_Invocations.append((bundle: bundle, context: context))

        if let error = sendCommitBundleIn_MockError {
            throw error
        }

        if let mock = sendCommitBundleIn_MockMethod {
            return try await mock(bundle, context)
        } else if let mock = sendCommitBundleIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendCommitBundleIn`")
        }
    }

    // MARK: - fetchConversationGroupInfo

    var fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations: [(conversationId: UUID, domain: String, subgroupType: SubgroupType?, context: NotificationContext)] = []
    var fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockError: Error?
    var fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockMethod: ((UUID, String, SubgroupType?, NotificationContext) async throws -> Data)?
    var fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue: Data?

    func fetchConversationGroupInfo(conversationId: UUID, domain: String, subgroupType: SubgroupType?, context: NotificationContext) async throws -> Data {
        fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations.append((conversationId: conversationId, domain: domain, subgroupType: subgroupType, context: context))

        if let error = fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockError {
            throw error
        }

        if let mock = fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockMethod {
            return try await mock(conversationId, domain, subgroupType, context)
        } else if let mock = fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext`")
        }
    }

    // MARK: - fetchSubgroup

    var fetchSubgroupConversationIDDomainTypeContext_Invocations: [(conversationID: UUID, domain: String, type: SubgroupType, context: NotificationContext)] = []
    var fetchSubgroupConversationIDDomainTypeContext_MockError: Error?
    var fetchSubgroupConversationIDDomainTypeContext_MockMethod: ((UUID, String, SubgroupType, NotificationContext) async throws -> MLSSubgroup)?
    var fetchSubgroupConversationIDDomainTypeContext_MockValue: MLSSubgroup?

    func fetchSubgroup(conversationID: UUID, domain: String, type: SubgroupType, context: NotificationContext) async throws -> MLSSubgroup {
        fetchSubgroupConversationIDDomainTypeContext_Invocations.append((conversationID: conversationID, domain: domain, type: type, context: context))

        if let error = fetchSubgroupConversationIDDomainTypeContext_MockError {
            throw error
        }

        if let mock = fetchSubgroupConversationIDDomainTypeContext_MockMethod {
            return try await mock(conversationID, domain, type, context)
        } else if let mock = fetchSubgroupConversationIDDomainTypeContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSubgroupConversationIDDomainTypeContext`")
        }
    }

    // MARK: - deleteSubgroup

    var deleteSubgroupConversationIDDomainSubgroupTypeContext_Invocations: [(conversationID: UUID, domain: String, subgroupType: SubgroupType, context: NotificationContext)] = []
    var deleteSubgroupConversationIDDomainSubgroupTypeContext_MockError: Error?
    var deleteSubgroupConversationIDDomainSubgroupTypeContext_MockMethod: ((UUID, String, SubgroupType, NotificationContext) async throws -> Void)?

    func deleteSubgroup(conversationID: UUID, domain: String, subgroupType: SubgroupType, context: NotificationContext) async throws {
        deleteSubgroupConversationIDDomainSubgroupTypeContext_Invocations.append((conversationID: conversationID, domain: domain, subgroupType: subgroupType, context: context))

        if let error = deleteSubgroupConversationIDDomainSubgroupTypeContext_MockError {
            throw error
        }

        guard let mock = deleteSubgroupConversationIDDomainSubgroupTypeContext_MockMethod else {
            fatalError("no mock for `deleteSubgroupConversationIDDomainSubgroupTypeContext`")
        }

        try await mock(conversationID, domain, subgroupType, context)
    }

    // MARK: - leaveSubconversation

    var leaveSubconversationConversationIDDomainSubconversationTypeContext_Invocations: [(conversationID: UUID, domain: String, subconversationType: SubgroupType, context: NotificationContext)] = []
    var leaveSubconversationConversationIDDomainSubconversationTypeContext_MockError: Error?
    var leaveSubconversationConversationIDDomainSubconversationTypeContext_MockMethod: ((UUID, String, SubgroupType, NotificationContext) async throws -> Void)?

    func leaveSubconversation(conversationID: UUID, domain: String, subconversationType: SubgroupType, context: NotificationContext) async throws {
        leaveSubconversationConversationIDDomainSubconversationTypeContext_Invocations.append((conversationID: conversationID, domain: domain, subconversationType: subconversationType, context: context))

        if let error = leaveSubconversationConversationIDDomainSubconversationTypeContext_MockError {
            throw error
        }

        guard let mock = leaveSubconversationConversationIDDomainSubconversationTypeContext_MockMethod else {
            fatalError("no mock for `leaveSubconversationConversationIDDomainSubconversationTypeContext`")
        }

        try await mock(conversationID, domain, subconversationType, context)
    }

    // MARK: - syncConversation

    var syncConversationQualifiedIDContext_Invocations: [(qualifiedID: QualifiedID, context: NotificationContext)] = []
    var syncConversationQualifiedIDContext_MockError: Error?
    var syncConversationQualifiedIDContext_MockMethod: ((QualifiedID, NotificationContext) async throws -> Void)?

    func syncConversation(qualifiedID: QualifiedID, context: NotificationContext) async throws {
        syncConversationQualifiedIDContext_Invocations.append((qualifiedID: qualifiedID, context: context))

        if let error = syncConversationQualifiedIDContext_MockError {
            throw error
        }

        guard let mock = syncConversationQualifiedIDContext_MockMethod else {
            fatalError("no mock for `syncConversationQualifiedIDContext`")
        }

        try await mock(qualifiedID, context)
    }

}

public class MockMLSDecryptionServiceInterface: MLSDecryptionServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - onEpochChanged

    public var onEpochChanged_Invocations: [Void] = []
    public var onEpochChanged_MockMethod: (() -> AnyPublisher<MLSGroupID, Never>)?
    public var onEpochChanged_MockValue: AnyPublisher<MLSGroupID, Never>?

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        onEpochChanged_Invocations.append(())

        if let mock = onEpochChanged_MockMethod {
            return mock()
        } else if let mock = onEpochChanged_MockValue {
            return mock
        } else {
            fatalError("no mock for `onEpochChanged`")
        }
    }

    // MARK: - decrypt

    public var decryptMessageForSubconversationType_Invocations: [(message: String, groupID: MLSGroupID, subconversationType: SubgroupType?)] = []
    public var decryptMessageForSubconversationType_MockError: Error?
    public var decryptMessageForSubconversationType_MockMethod: ((String, MLSGroupID, SubgroupType?) throws -> MLSDecryptResult?)?
    public var decryptMessageForSubconversationType_MockValue: MLSDecryptResult??

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?) throws -> MLSDecryptResult? {
        decryptMessageForSubconversationType_Invocations.append((message: message, groupID: groupID, subconversationType: subconversationType))

        if let error = decryptMessageForSubconversationType_MockError {
            throw error
        }

        if let mock = decryptMessageForSubconversationType_MockMethod {
            return try mock(message, groupID, subconversationType)
        } else if let mock = decryptMessageForSubconversationType_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptMessageForSubconversationType`")
        }
    }

}

public class MockMLSEncryptionServiceInterface: MLSEncryptionServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - encrypt

    public var encryptMessageFor_Invocations: [(message: [Byte], groupID: MLSGroupID)] = []
    public var encryptMessageFor_MockError: Error?
    public var encryptMessageFor_MockMethod: (([Byte], MLSGroupID) throws -> [Byte])?
    public var encryptMessageFor_MockValue: [Byte]?

    public func encrypt(message: [Byte], for groupID: MLSGroupID) throws -> [Byte] {
        encryptMessageFor_Invocations.append((message: message, groupID: groupID))

        if let error = encryptMessageFor_MockError {
            throw error
        }

        if let mock = encryptMessageFor_MockMethod {
            return try mock(message, groupID)
        } else if let mock = encryptMessageFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptMessageFor`")
        }
    }

}

public class MockMLSServiceInterface: MLSServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - uploadKeyPackagesIfNeeded

    public var uploadKeyPackagesIfNeeded_Invocations: [Void] = []
    public var uploadKeyPackagesIfNeeded_MockMethod: (() async -> Void)?

    public func uploadKeyPackagesIfNeeded() async {
        uploadKeyPackagesIfNeeded_Invocations.append(())

        guard let mock = uploadKeyPackagesIfNeeded_MockMethod else {
            fatalError("no mock for `uploadKeyPackagesIfNeeded`")
        }

        await mock()
    }

    // MARK: - createSelfGroup

    public var createSelfGroupFor_Invocations: [MLSGroupID] = []
    public var createSelfGroupFor_MockMethod: ((MLSGroupID) async -> Void)?

    public func createSelfGroup(for groupID: MLSGroupID) async {
        createSelfGroupFor_Invocations.append(groupID)

        guard let mock = createSelfGroupFor_MockMethod else {
            fatalError("no mock for `createSelfGroupFor`")
        }

        await mock(groupID)
    }

    // MARK: - joinGroup

    public var joinGroupWith_Invocations: [MLSGroupID] = []
    public var joinGroupWith_MockError: Error?
    public var joinGroupWith_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func joinGroup(with groupID: MLSGroupID) async throws {
        joinGroupWith_Invocations.append(groupID)

        if let error = joinGroupWith_MockError {
            throw error
        }

        guard let mock = joinGroupWith_MockMethod else {
            fatalError("no mock for `joinGroupWith`")
        }

        try await mock(groupID)
    }

    // MARK: - joinNewGroup

    public var joinNewGroupWith_Invocations: [MLSGroupID] = []
    public var joinNewGroupWith_MockError: Error?
    public var joinNewGroupWith_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func joinNewGroup(with groupID: MLSGroupID) async throws {
        joinNewGroupWith_Invocations.append(groupID)

        if let error = joinNewGroupWith_MockError {
            throw error
        }

        guard let mock = joinNewGroupWith_MockMethod else {
            fatalError("no mock for `joinNewGroupWith`")
        }

        try await mock(groupID)
    }

    // MARK: - createGroup

    public var createGroupFor_Invocations: [MLSGroupID] = []
    public var createGroupFor_MockError: Error?
    public var createGroupFor_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func createGroup(for groupID: MLSGroupID) async throws {
        createGroupFor_Invocations.append(groupID)

        if let error = createGroupFor_MockError {
            throw error
        }

        guard let mock = createGroupFor_MockMethod else {
            fatalError("no mock for `createGroupFor`")
        }

        try await mock(groupID)
    }

    // MARK: - conversationExists

    public var conversationExistsGroupID_Invocations: [MLSGroupID] = []
    public var conversationExistsGroupID_MockMethod: ((MLSGroupID) -> Bool)?
    public var conversationExistsGroupID_MockValue: Bool?

    public func conversationExists(groupID: MLSGroupID) -> Bool {
        conversationExistsGroupID_Invocations.append(groupID)

        if let mock = conversationExistsGroupID_MockMethod {
            return mock(groupID)
        } else if let mock = conversationExistsGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationExistsGroupID`")
        }
    }

    // MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessage_Invocations: [String] = []
    public var processWelcomeMessageWelcomeMessage_MockError: Error?
    public var processWelcomeMessageWelcomeMessage_MockMethod: ((String) async throws -> MLSGroupID)?
    public var processWelcomeMessageWelcomeMessage_MockValue: MLSGroupID?

    public func processWelcomeMessage(welcomeMessage: String) async throws -> MLSGroupID {
        processWelcomeMessageWelcomeMessage_Invocations.append(welcomeMessage)

        if let error = processWelcomeMessageWelcomeMessage_MockError {
            throw error
        }

        if let mock = processWelcomeMessageWelcomeMessage_MockMethod {
            return try await mock(welcomeMessage)
        } else if let mock = processWelcomeMessageWelcomeMessage_MockValue {
            return mock
        } else {
            fatalError("no mock for `processWelcomeMessageWelcomeMessage`")
        }
    }

    // MARK: - addMembersToConversation

    public var addMembersToConversationWithFor_Invocations: [(users: [MLSUser], groupID: MLSGroupID)] = []
    public var addMembersToConversationWithFor_MockError: Error?
    public var addMembersToConversationWithFor_MockMethod: (([MLSUser], MLSGroupID) async throws -> Void)?

    public func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws {
        addMembersToConversationWithFor_Invocations.append((users: users, groupID: groupID))

        if let error = addMembersToConversationWithFor_MockError {
            throw error
        }

        guard let mock = addMembersToConversationWithFor_MockMethod else {
            fatalError("no mock for `addMembersToConversationWithFor`")
        }

        try await mock(users, groupID)
    }

    // MARK: - removeMembersFromConversation

    public var removeMembersFromConversationWithFor_Invocations: [(clientIds: [MLSClientID], groupID: MLSGroupID)] = []
    public var removeMembersFromConversationWithFor_MockError: Error?
    public var removeMembersFromConversationWithFor_MockMethod: (([MLSClientID], MLSGroupID) async throws -> Void)?

    public func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) async throws {
        removeMembersFromConversationWithFor_Invocations.append((clientIds: clientIds, groupID: groupID))

        if let error = removeMembersFromConversationWithFor_MockError {
            throw error
        }

        guard let mock = removeMembersFromConversationWithFor_MockMethod else {
            fatalError("no mock for `removeMembersFromConversationWithFor`")
        }

        try await mock(clientIds, groupID)
    }

    // MARK: - registerPendingJoin

    public var registerPendingJoin_Invocations: [MLSGroupID] = []
    public var registerPendingJoin_MockMethod: ((MLSGroupID) -> Void)?

    public func registerPendingJoin(_ group: MLSGroupID) {
        registerPendingJoin_Invocations.append(group)

        guard let mock = registerPendingJoin_MockMethod else {
            fatalError("no mock for `registerPendingJoin`")
        }

        mock(group)
    }

    // MARK: - performPendingJoins

    public var performPendingJoins_Invocations: [Void] = []
    public var performPendingJoins_MockError: Error?
    public var performPendingJoins_MockMethod: (() async throws -> Void)?

    public func performPendingJoins() async throws {
        performPendingJoins_Invocations.append(())

        if let error = performPendingJoins_MockError {
            throw error
        }

        guard let mock = performPendingJoins_MockMethod else {
            fatalError("no mock for `performPendingJoins`")
        }

        try await mock()
    }

    // MARK: - wipeGroup

    public var wipeGroup_Invocations: [MLSGroupID] = []
    public var wipeGroup_MockMethod: ((MLSGroupID) async -> Void)?

    public func wipeGroup(_ groupID: MLSGroupID) async {
        wipeGroup_Invocations.append(groupID)

        guard let mock = wipeGroup_MockMethod else {
            fatalError("no mock for `wipeGroup`")
        }

        await mock(groupID)
    }

    // MARK: - commitPendingProposals

    public var commitPendingProposals_Invocations: [Void] = []
    public var commitPendingProposals_MockError: Error?
    public var commitPendingProposals_MockMethod: (() async throws -> Void)?

    public func commitPendingProposals() async throws {
        commitPendingProposals_Invocations.append(())

        if let error = commitPendingProposals_MockError {
            throw error
        }

        guard let mock = commitPendingProposals_MockMethod else {
            fatalError("no mock for `commitPendingProposals`")
        }

        try await mock()
    }

    // MARK: - commitPendingProposals

    public var commitPendingProposalsIn_Invocations: [MLSGroupID] = []
    public var commitPendingProposalsIn_MockError: Error?
    public var commitPendingProposalsIn_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func commitPendingProposals(in groupID: MLSGroupID) async throws {
        commitPendingProposalsIn_Invocations.append(groupID)

        if let error = commitPendingProposalsIn_MockError {
            throw error
        }

        guard let mock = commitPendingProposalsIn_MockMethod else {
            fatalError("no mock for `commitPendingProposalsIn`")
        }

        try await mock(groupID)
    }

    // MARK: - createOrJoinSubgroup

    public var createOrJoinSubgroupParentQualifiedIDParentID_Invocations: [(parentQualifiedID: QualifiedID, parentID: MLSGroupID)] = []
    public var createOrJoinSubgroupParentQualifiedIDParentID_MockError: Error?
    public var createOrJoinSubgroupParentQualifiedIDParentID_MockMethod: ((QualifiedID, MLSGroupID) async throws -> MLSGroupID)?
    public var createOrJoinSubgroupParentQualifiedIDParentID_MockValue: MLSGroupID?

    public func createOrJoinSubgroup(parentQualifiedID: QualifiedID, parentID: MLSGroupID) async throws -> MLSGroupID {
        createOrJoinSubgroupParentQualifiedIDParentID_Invocations.append((parentQualifiedID: parentQualifiedID, parentID: parentID))

        if let error = createOrJoinSubgroupParentQualifiedIDParentID_MockError {
            throw error
        }

        if let mock = createOrJoinSubgroupParentQualifiedIDParentID_MockMethod {
            return try await mock(parentQualifiedID, parentID)
        } else if let mock = createOrJoinSubgroupParentQualifiedIDParentID_MockValue {
            return mock
        } else {
            fatalError("no mock for `createOrJoinSubgroupParentQualifiedIDParentID`")
        }
    }

    // MARK: - generateConferenceInfo

    public var generateConferenceInfoParentGroupIDSubconversationGroupID_Invocations: [(parentGroupID: MLSGroupID, subconversationGroupID: MLSGroupID)] = []
    public var generateConferenceInfoParentGroupIDSubconversationGroupID_MockError: Error?
    public var generateConferenceInfoParentGroupIDSubconversationGroupID_MockMethod: ((MLSGroupID, MLSGroupID) async throws -> MLSConferenceInfo)?
    public var generateConferenceInfoParentGroupIDSubconversationGroupID_MockValue: MLSConferenceInfo?

    public func generateConferenceInfo(parentGroupID: MLSGroupID, subconversationGroupID: MLSGroupID) async throws -> MLSConferenceInfo {
        generateConferenceInfoParentGroupIDSubconversationGroupID_Invocations.append((parentGroupID: parentGroupID, subconversationGroupID: subconversationGroupID))

        if let error = generateConferenceInfoParentGroupIDSubconversationGroupID_MockError {
            throw error
        }

        if let mock = generateConferenceInfoParentGroupIDSubconversationGroupID_MockMethod {
            return try await mock(parentGroupID, subconversationGroupID)
        } else if let mock = generateConferenceInfoParentGroupIDSubconversationGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `generateConferenceInfoParentGroupIDSubconversationGroupID`")
        }
    }

    // MARK: - onConferenceInfoChange

    public var onConferenceInfoChangeParentGroupIDSubConversationGroupID_Invocations: [(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID)] = []
    public var onConferenceInfoChangeParentGroupIDSubConversationGroupID_MockMethod: ((MLSGroupID, MLSGroupID) -> AsyncThrowingStream<MLSConferenceInfo, Error>)?
    public var onConferenceInfoChangeParentGroupIDSubConversationGroupID_MockValue: AsyncThrowingStream<MLSConferenceInfo, Error>?

    public func onConferenceInfoChange(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID) -> AsyncThrowingStream<MLSConferenceInfo, Error> {
        onConferenceInfoChangeParentGroupIDSubConversationGroupID_Invocations.append((parentGroupID: parentGroupID, subConversationGroupID: subConversationGroupID))

        if let mock = onConferenceInfoChangeParentGroupIDSubConversationGroupID_MockMethod {
            return mock(parentGroupID, subConversationGroupID)
        } else if let mock = onConferenceInfoChangeParentGroupIDSubConversationGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `onConferenceInfoChangeParentGroupIDSubConversationGroupID`")
        }
    }

    // MARK: - leaveSubconversationIfNeeded

    public var leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_Invocations: [(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType, selfClientID: MLSClientID)] = []
    public var leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockError: Error?
    public var leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockMethod: ((QualifiedID, MLSGroupID, SubgroupType, MLSClientID) async throws -> Void)?

    public func leaveSubconversationIfNeeded(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType, selfClientID: MLSClientID) async throws {
        leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_Invocations.append((parentQualifiedID: parentQualifiedID, parentGroupID: parentGroupID, subconversationType: subconversationType, selfClientID: selfClientID))

        if let error = leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockError {
            throw error
        }

        guard let mock = leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID_MockMethod else {
            fatalError("no mock for `leaveSubconversationIfNeededParentQualifiedIDParentGroupIDSubconversationTypeSelfClientID`")
        }

        try await mock(parentQualifiedID, parentGroupID, subconversationType, selfClientID)
    }

    // MARK: - leaveSubconversation

    public var leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_Invocations: [(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType)] = []
    public var leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_MockError: Error?
    public var leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_MockMethod: ((QualifiedID, MLSGroupID, SubgroupType) async throws -> Void)?

    public func leaveSubconversation(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType) async throws {
        leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_Invocations.append((parentQualifiedID: parentQualifiedID, parentGroupID: parentGroupID, subconversationType: subconversationType))

        if let error = leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_MockError {
            throw error
        }

        guard let mock = leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType_MockMethod else {
            fatalError("no mock for `leaveSubconversationParentQualifiedIDParentGroupIDSubconversationType`")
        }

        try await mock(parentQualifiedID, parentGroupID, subconversationType)
    }

    // MARK: - generateNewEpoch

    public var generateNewEpochGroupID_Invocations: [MLSGroupID] = []
    public var generateNewEpochGroupID_MockError: Error?
    public var generateNewEpochGroupID_MockMethod: ((MLSGroupID) async throws -> Void)?

    public func generateNewEpoch(groupID: MLSGroupID) async throws {
        generateNewEpochGroupID_Invocations.append(groupID)

        if let error = generateNewEpochGroupID_MockError {
            throw error
        }

        guard let mock = generateNewEpochGroupID_MockMethod else {
            fatalError("no mock for `generateNewEpochGroupID`")
        }

        try await mock(groupID)
    }

    // MARK: - subconversationMembers

    public var subconversationMembersFor_Invocations: [MLSGroupID] = []
    public var subconversationMembersFor_MockError: Error?
    public var subconversationMembersFor_MockMethod: ((MLSGroupID) async throws -> [MLSClientID])?
    public var subconversationMembersFor_MockValue: [MLSClientID]?

    public func subconversationMembers(for subconversationGroupID: MLSGroupID) async throws -> [MLSClientID] {
        subconversationMembersFor_Invocations.append(subconversationGroupID)

        if let error = subconversationMembersFor_MockError {
            throw error
        }

        if let mock = subconversationMembersFor_MockMethod {
            return try await mock(subconversationGroupID)
        } else if let mock = subconversationMembersFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `subconversationMembersFor`")
        }
    }

    // MARK: - repairOutOfSyncConversations

    public var repairOutOfSyncConversations_Invocations: [Void] = []
    public var repairOutOfSyncConversations_MockMethod: (() -> Void)?

    public func repairOutOfSyncConversations() {
        repairOutOfSyncConversations_Invocations.append(())

        guard let mock = repairOutOfSyncConversations_MockMethod else {
            fatalError("no mock for `repairOutOfSyncConversations`")
        }

        mock()
    }

    // MARK: - fetchAndRepairGroup

    public var fetchAndRepairGroupWith_Invocations: [MLSGroupID] = []
    public var fetchAndRepairGroupWith_MockMethod: ((MLSGroupID) async -> Void)?

    public func fetchAndRepairGroup(with groupID: MLSGroupID) async {
        fetchAndRepairGroupWith_Invocations.append(groupID)

        guard let mock = fetchAndRepairGroupWith_MockMethod else {
            fatalError("no mock for `fetchAndRepairGroupWith`")
        }

        await mock(groupID)
    }

    // MARK: - updateKeyMaterialForAllStaleGroupsIfNeeded

    public var updateKeyMaterialForAllStaleGroupsIfNeeded_Invocations: [Void] = []
    public var updateKeyMaterialForAllStaleGroupsIfNeeded_MockMethod: (() async -> Void)?

    public func updateKeyMaterialForAllStaleGroupsIfNeeded() async {
        updateKeyMaterialForAllStaleGroupsIfNeeded_Invocations.append(())

        guard let mock = updateKeyMaterialForAllStaleGroupsIfNeeded_MockMethod else {
            fatalError("no mock for `updateKeyMaterialForAllStaleGroupsIfNeeded`")
        }

        await mock()
    }

    // MARK: - onEpochChanged

    public var onEpochChanged_Invocations: [Void] = []
    public var onEpochChanged_MockMethod: (() -> AnyPublisher<MLSGroupID, Never>)?
    public var onEpochChanged_MockValue: AnyPublisher<MLSGroupID, Never>?

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        onEpochChanged_Invocations.append(())

        if let mock = onEpochChanged_MockMethod {
            return mock()
        } else if let mock = onEpochChanged_MockValue {
            return mock
        } else {
            fatalError("no mock for `onEpochChanged`")
        }
    }

    // MARK: - decrypt

    public var decryptMessageForSubconversationType_Invocations: [(message: String, groupID: MLSGroupID, subconversationType: SubgroupType?)] = []
    public var decryptMessageForSubconversationType_MockError: Error?
    public var decryptMessageForSubconversationType_MockMethod: ((String, MLSGroupID, SubgroupType?) throws -> MLSDecryptResult?)?
    public var decryptMessageForSubconversationType_MockValue: MLSDecryptResult??

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?) throws -> MLSDecryptResult? {
        decryptMessageForSubconversationType_Invocations.append((message: message, groupID: groupID, subconversationType: subconversationType))

        if let error = decryptMessageForSubconversationType_MockError {
            throw error
        }

        if let mock = decryptMessageForSubconversationType_MockMethod {
            return try mock(message, groupID, subconversationType)
        } else if let mock = decryptMessageForSubconversationType_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptMessageForSubconversationType`")
        }
    }

    // MARK: - encrypt

    public var encryptMessageFor_Invocations: [(message: [Byte], groupID: MLSGroupID)] = []
    public var encryptMessageFor_MockError: Error?
    public var encryptMessageFor_MockMethod: (([Byte], MLSGroupID) throws -> [Byte])?
    public var encryptMessageFor_MockValue: [Byte]?

    public func encrypt(message: [Byte], for groupID: MLSGroupID) throws -> [Byte] {
        encryptMessageFor_Invocations.append((message: message, groupID: groupID))

        if let error = encryptMessageFor_MockError {
            throw error
        }

        if let mock = encryptMessageFor_MockMethod {
            return try mock(message, groupID)
        } else if let mock = encryptMessageFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptMessageFor`")
        }
    }

}

public class MockProteusServiceInterface: ProteusServiceInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - lastPrekeyID

    public var lastPrekeyID: UInt16 {
        get { return underlyingLastPrekeyID }
        set(value) { underlyingLastPrekeyID = value }
    }

    public var underlyingLastPrekeyID: UInt16!


    // MARK: - establishSession

    public var establishSessionIdFromPrekey_Invocations: [(id: ProteusSessionID, fromPrekey: String)] = []
    public var establishSessionIdFromPrekey_MockError: Error?
    public var establishSessionIdFromPrekey_MockMethod: ((ProteusSessionID, String) throws -> Void)?

    public func establishSession(id: ProteusSessionID, fromPrekey: String) throws {
        establishSessionIdFromPrekey_Invocations.append((id: id, fromPrekey: fromPrekey))

        if let error = establishSessionIdFromPrekey_MockError {
            throw error
        }

        guard let mock = establishSessionIdFromPrekey_MockMethod else {
            fatalError("no mock for `establishSessionIdFromPrekey`")
        }

        try mock(id, fromPrekey)
    }

    // MARK: - deleteSession

    public var deleteSessionId_Invocations: [ProteusSessionID] = []
    public var deleteSessionId_MockError: Error?
    public var deleteSessionId_MockMethod: ((ProteusSessionID) throws -> Void)?

    public func deleteSession(id: ProteusSessionID) throws {
        deleteSessionId_Invocations.append(id)

        if let error = deleteSessionId_MockError {
            throw error
        }

        guard let mock = deleteSessionId_MockMethod else {
            fatalError("no mock for `deleteSessionId`")
        }

        try mock(id)
    }

    // MARK: - sessionExists

    public var sessionExistsId_Invocations: [ProteusSessionID] = []
    public var sessionExistsId_MockMethod: ((ProteusSessionID) -> Bool)?
    public var sessionExistsId_MockValue: Bool?

    public func sessionExists(id: ProteusSessionID) -> Bool {
        sessionExistsId_Invocations.append(id)

        if let mock = sessionExistsId_MockMethod {
            return mock(id)
        } else if let mock = sessionExistsId_MockValue {
            return mock
        } else {
            fatalError("no mock for `sessionExistsId`")
        }
    }

    // MARK: - encrypt

    public var encryptDataForSession_Invocations: [(data: Data, id: ProteusSessionID)] = []
    public var encryptDataForSession_MockError: Error?
    public var encryptDataForSession_MockMethod: ((Data, ProteusSessionID) throws -> Data)?
    public var encryptDataForSession_MockValue: Data?

    public func encrypt(data: Data, forSession id: ProteusSessionID) throws -> Data {
        encryptDataForSession_Invocations.append((data: data, id: id))

        if let error = encryptDataForSession_MockError {
            throw error
        }

        if let mock = encryptDataForSession_MockMethod {
            return try mock(data, id)
        } else if let mock = encryptDataForSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptDataForSession`")
        }
    }

    // MARK: - encryptBatched

    public var encryptBatchedDataForSessions_Invocations: [(data: Data, sessions: [ProteusSessionID])] = []
    public var encryptBatchedDataForSessions_MockError: Error?
    public var encryptBatchedDataForSessions_MockMethod: ((Data, [ProteusSessionID]) throws -> [String: Data])?
    public var encryptBatchedDataForSessions_MockValue: [String: Data]?

    public func encryptBatched(data: Data, forSessions sessions: [ProteusSessionID]) throws -> [String: Data] {
        encryptBatchedDataForSessions_Invocations.append((data: data, sessions: sessions))

        if let error = encryptBatchedDataForSessions_MockError {
            throw error
        }

        if let mock = encryptBatchedDataForSessions_MockMethod {
            return try mock(data, sessions)
        } else if let mock = encryptBatchedDataForSessions_MockValue {
            return mock
        } else {
            fatalError("no mock for `encryptBatchedDataForSessions`")
        }
    }

    // MARK: - decrypt

    public var decryptDataForSession_Invocations: [(data: Data, id: ProteusSessionID)] = []
    public var decryptDataForSession_MockError: Error?
    public var decryptDataForSession_MockMethod: ((Data, ProteusSessionID) async throws -> (didCreateNewSession: Bool, decryptedData: Data))?
    public var decryptDataForSession_MockValue: (didCreateNewSession: Bool, decryptedData: Data)?

    public func decrypt(data: Data, forSession id: ProteusSessionID) async throws -> (didCreateNewSession: Bool, decryptedData: Data) {
        decryptDataForSession_Invocations.append((data: data, id: id))

        if let error = decryptDataForSession_MockError {
            throw error
        }

        if let mock = decryptDataForSession_MockMethod {
            return try await mock(data, id)
        } else if let mock = decryptDataForSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptDataForSession`")
        }
    }

    // MARK: - generatePrekey

    public var generatePrekeyId_Invocations: [UInt16] = []
    public var generatePrekeyId_MockError: Error?
    public var generatePrekeyId_MockMethod: ((UInt16) async throws -> String)?
    public var generatePrekeyId_MockValue: String?

    public func generatePrekey(id: UInt16) async throws -> String {
        generatePrekeyId_Invocations.append(id)

        if let error = generatePrekeyId_MockError {
            throw error
        }

        if let mock = generatePrekeyId_MockMethod {
            return try await mock(id)
        } else if let mock = generatePrekeyId_MockValue {
            return mock
        } else {
            fatalError("no mock for `generatePrekeyId`")
        }
    }

    // MARK: - lastPrekey

    public var lastPrekey_Invocations: [Void] = []
    public var lastPrekey_MockError: Error?
    public var lastPrekey_MockMethod: (() async throws -> String)?
    public var lastPrekey_MockValue: String?

    public func lastPrekey() async throws -> String {
        lastPrekey_Invocations.append(())

        if let error = lastPrekey_MockError {
            throw error
        }

        if let mock = lastPrekey_MockMethod {
            return try await mock()
        } else if let mock = lastPrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `lastPrekey`")
        }
    }

    // MARK: - generatePrekeys

    public var generatePrekeysStartCount_Invocations: [(start: UInt16, count: UInt16)] = []
    public var generatePrekeysStartCount_MockError: Error?
    public var generatePrekeysStartCount_MockMethod: ((UInt16, UInt16) async throws -> [IdPrekeyTuple])?
    public var generatePrekeysStartCount_MockValue: [IdPrekeyTuple]?

    public func generatePrekeys(start: UInt16, count: UInt16) async throws -> [IdPrekeyTuple] {
        generatePrekeysStartCount_Invocations.append((start: start, count: count))

        if let error = generatePrekeysStartCount_MockError {
            throw error
        }

        if let mock = generatePrekeysStartCount_MockMethod {
            return try await mock(start, count)
        } else if let mock = generatePrekeysStartCount_MockValue {
            return mock
        } else {
            fatalError("no mock for `generatePrekeysStartCount`")
        }
    }

    // MARK: - localFingerprint

    public var localFingerprint_Invocations: [Void] = []
    public var localFingerprint_MockError: Error?
    public var localFingerprint_MockMethod: (() throws -> String)?
    public var localFingerprint_MockValue: String?

    public func localFingerprint() throws -> String {
        localFingerprint_Invocations.append(())

        if let error = localFingerprint_MockError {
            throw error
        }

        if let mock = localFingerprint_MockMethod {
            return try mock()
        } else if let mock = localFingerprint_MockValue {
            return mock
        } else {
            fatalError("no mock for `localFingerprint`")
        }
    }

    // MARK: - remoteFingerprint

    public var remoteFingerprintForSession_Invocations: [ProteusSessionID] = []
    public var remoteFingerprintForSession_MockError: Error?
    public var remoteFingerprintForSession_MockMethod: ((ProteusSessionID) throws -> String)?
    public var remoteFingerprintForSession_MockValue: String?

    public func remoteFingerprint(forSession id: ProteusSessionID) throws -> String {
        remoteFingerprintForSession_Invocations.append(id)

        if let error = remoteFingerprintForSession_MockError {
            throw error
        }

        if let mock = remoteFingerprintForSession_MockMethod {
            return try mock(id)
        } else if let mock = remoteFingerprintForSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `remoteFingerprintForSession`")
        }
    }

    // MARK: - fingerprint

    public var fingerprintFromPrekey_Invocations: [String] = []
    public var fingerprintFromPrekey_MockError: Error?
    public var fingerprintFromPrekey_MockMethod: ((String) throws -> String)?
    public var fingerprintFromPrekey_MockValue: String?

    public func fingerprint(fromPrekey prekey: String) throws -> String {
        fingerprintFromPrekey_Invocations.append(prekey)

        if let error = fingerprintFromPrekey_MockError {
            throw error
        }

        if let mock = fingerprintFromPrekey_MockMethod {
            return try mock(prekey)
        } else if let mock = fingerprintFromPrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `fingerprintFromPrekey`")
        }
    }

}

public class MockSubconversationGroupIDRepositoryInterface: SubconversationGroupIDRepositoryInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - storeSubconversationGroupID

    public var storeSubconversationGroupIDForTypeParentGroupID_Invocations: [(groupID: MLSGroupID?, type: SubgroupType, parentGroupID: MLSGroupID)] = []
    public var storeSubconversationGroupIDForTypeParentGroupID_MockMethod: ((MLSGroupID?, SubgroupType, MLSGroupID) -> Void)?

    public func storeSubconversationGroupID(_ groupID: MLSGroupID?, forType type: SubgroupType, parentGroupID: MLSGroupID) {
        storeSubconversationGroupIDForTypeParentGroupID_Invocations.append((groupID: groupID, type: type, parentGroupID: parentGroupID))

        guard let mock = storeSubconversationGroupIDForTypeParentGroupID_MockMethod else {
            fatalError("no mock for `storeSubconversationGroupIDForTypeParentGroupID`")
        }

        mock(groupID, type, parentGroupID)
    }

    // MARK: - fetchSubconversationGroupID

    public var fetchSubconversationGroupIDForTypeParentGroupID_Invocations: [(type: SubgroupType, parentGroupID: MLSGroupID)] = []
    public var fetchSubconversationGroupIDForTypeParentGroupID_MockMethod: ((SubgroupType, MLSGroupID) -> MLSGroupID?)?
    public var fetchSubconversationGroupIDForTypeParentGroupID_MockValue: MLSGroupID??

    public func fetchSubconversationGroupID(forType type: SubgroupType, parentGroupID: MLSGroupID) -> MLSGroupID? {
        fetchSubconversationGroupIDForTypeParentGroupID_Invocations.append((type: type, parentGroupID: parentGroupID))

        if let mock = fetchSubconversationGroupIDForTypeParentGroupID_MockMethod {
            return mock(type, parentGroupID)
        } else if let mock = fetchSubconversationGroupIDForTypeParentGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSubconversationGroupIDForTypeParentGroupID`")
        }
    }

    // MARK: - findSubgroupTypeAndParentID

    public var findSubgroupTypeAndParentIDFor_Invocations: [MLSGroupID] = []
    public var findSubgroupTypeAndParentIDFor_MockMethod: ((MLSGroupID) -> (parentID: MLSGroupID, type: SubgroupType)?)?
    public var findSubgroupTypeAndParentIDFor_MockValue: (parentID: MLSGroupID, type: SubgroupType)??

    public func findSubgroupTypeAndParentID(for targetGroupID: MLSGroupID) -> (parentID: MLSGroupID, type: SubgroupType)? {
        findSubgroupTypeAndParentIDFor_Invocations.append(targetGroupID)

        if let mock = findSubgroupTypeAndParentIDFor_MockMethod {
            return mock(targetGroupID)
        } else if let mock = findSubgroupTypeAndParentIDFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `findSubgroupTypeAndParentIDFor`")
        }
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
