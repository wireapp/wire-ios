// Generated using Sourcery 1.8.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif


@testable import WireDataModel





















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
    public var fetchPublicKeys_MockMethod: (() throws -> EARPublicKeys)?
    public var fetchPublicKeys_MockValue: EARPublicKeys?

    public func fetchPublicKeys() throws -> EARPublicKeys {
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

    public var fetchPrivateKeys_Invocations: [Void] = []
    public var fetchPrivateKeys_MockError: Error?
    public var fetchPrivateKeys_MockMethod: (() throws -> EARPrivateKeys)?
    public var fetchPrivateKeys_MockValue: EARPrivateKeys?

    public func fetchPrivateKeys() throws -> EARPrivateKeys {
        fetchPrivateKeys_Invocations.append(())

        if let error = fetchPrivateKeys_MockError {
            throw error
        }

        if let mock = fetchPrivateKeys_MockMethod {
            return try mock()
        } else if let mock = fetchPrivateKeys_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPrivateKeys`")
        }
    }

}
