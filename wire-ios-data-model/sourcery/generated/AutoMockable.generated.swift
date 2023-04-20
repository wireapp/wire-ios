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





















public class MockEARKeyRepositoryInterface: EARKeyRepositoryInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - generatePublicPrivateKeyPair

    public var generatePublicPrivateKeyPairId_Invocations: [String] = []
    public var generatePublicPrivateKeyPairId_MockError: Error?
    public var generatePublicPrivateKeyPairId_MockMethod: ((String) throws -> (publicKey: SecKey, privateKey: SecKey))?
    public var generatePublicPrivateKeyPairId_MockValue: (publicKey: SecKey, privateKey: SecKey)?

    public func generatePublicPrivateKeyPair(id: String) throws -> (publicKey: SecKey, privateKey: SecKey) {
        generatePublicPrivateKeyPairId_Invocations.append(id)

        if let error = generatePublicPrivateKeyPairId_MockError {
            throw error
        }

        if let mock = generatePublicPrivateKeyPairId_MockMethod {
            return try mock(id)
        } else if let mock = generatePublicPrivateKeyPairId_MockValue {
            return mock
        } else {
            fatalError("no mock for `generatePublicPrivateKeyPairId`")
        }
    }

    // MARK: - generateKey

    public var generateKeyNumberOfBytes_Invocations: [UInt] = []
    public var generateKeyNumberOfBytes_MockError: Error?
    public var generateKeyNumberOfBytes_MockMethod: ((UInt) throws -> Data)?
    public var generateKeyNumberOfBytes_MockValue: Data?

    public func generateKey(numberOfBytes: UInt) throws -> Data {
        generateKeyNumberOfBytes_Invocations.append(numberOfBytes)

        if let error = generateKeyNumberOfBytes_MockError {
            throw error
        }

        if let mock = generateKeyNumberOfBytes_MockMethod {
            return try mock(numberOfBytes)
        } else if let mock = generateKeyNumberOfBytes_MockValue {
            return mock
        } else {
            fatalError("no mock for `generateKeyNumberOfBytes`")
        }
    }

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
