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
    public var decryptDataForSession_MockMethod: ((Data, ProteusSessionID) throws -> (didCreateSession: Bool, decryptedData: Data))?
    public var decryptDataForSession_MockValue: (didCreateSession: Bool, decryptedData: Data)?

    public func decrypt(data: Data, forSession id: ProteusSessionID) throws -> (didCreateSession: Bool, decryptedData: Data) {
        decryptDataForSession_Invocations.append((data: data, id: id))

        if let error = decryptDataForSession_MockError {
            throw error
        }

        if let mock = decryptDataForSession_MockMethod {
            return try mock(data, id)
        } else if let mock = decryptDataForSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `decryptDataForSession`")
        }
    }

    // MARK: - generatePrekey

    public var generatePrekeyId_Invocations: [UInt16] = []
    public var generatePrekeyId_MockError: Error?
    public var generatePrekeyId_MockMethod: ((UInt16) throws -> String)?
    public var generatePrekeyId_MockValue: String?

    public func generatePrekey(id: UInt16) throws -> String {
        generatePrekeyId_Invocations.append(id)

        if let error = generatePrekeyId_MockError {
            throw error
        }

        if let mock = generatePrekeyId_MockMethod {
            return try mock(id)
        } else if let mock = generatePrekeyId_MockValue {
            return mock
        } else {
            fatalError("no mock for `generatePrekeyId`")
        }
    }

    // MARK: - lastPrekey

    public var lastPrekey_Invocations: [Void] = []
    public var lastPrekey_MockError: Error?
    public var lastPrekey_MockMethod: (() throws -> String)?
    public var lastPrekey_MockValue: String?

    public func lastPrekey() throws -> String {
        lastPrekey_Invocations.append(())

        if let error = lastPrekey_MockError {
            throw error
        }

        if let mock = lastPrekey_MockMethod {
            return try mock()
        } else if let mock = lastPrekey_MockValue {
            return mock
        } else {
            fatalError("no mock for `lastPrekey`")
        }
    }

    // MARK: - generatePrekeys

    public var generatePrekeysStartCount_Invocations: [(start: UInt16, count: UInt16)] = []
    public var generatePrekeysStartCount_MockError: Error?
    public var generatePrekeysStartCount_MockMethod: ((UInt16, UInt16) throws -> [IdPrekeyTuple])?
    public var generatePrekeysStartCount_MockValue: [IdPrekeyTuple]?

    public func generatePrekeys(start: UInt16, count: UInt16) throws -> [IdPrekeyTuple] {
        generatePrekeysStartCount_Invocations.append((start: start, count: count))

        if let error = generatePrekeysStartCount_MockError {
            throw error
        }

        if let mock = generatePrekeysStartCount_MockMethod {
            return try mock(start, count)
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
            fatalError("no mock for `fingerprint`")
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

    // MARK: - performBatchedOperations

    public var performBatchedOperations_Invocations: [() throws -> Void] = []
    public var performBatchedOperations_MockMethod: ((@escaping () throws -> Void) -> Void)?

    public func performBatchedOperations(_ block: @escaping () throws -> Void) {
        performBatchedOperations_Invocations.append(block)

        guard let mock = performBatchedOperations_MockMethod else {
            fatalError("no mock for `performBatchedOperations`")
        }

        mock(block)            
    }

}
