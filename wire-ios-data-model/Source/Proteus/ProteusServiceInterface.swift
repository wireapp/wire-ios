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

// MARK: - ProteusServiceInterface

// swiftlint:disable orphaned_doc_comment

/// A type that provides support for messaging via the Proteus
/// end-to-end-encryption protocol.

// sourcery: AutoMockable
public protocol ProteusServiceInterface {
    func establishSession(id: ProteusSessionID, fromPrekey: String) async throws
    func deleteSession(id: ProteusSessionID) async throws
    func sessionExists(id: ProteusSessionID) async -> Bool
    func encrypt(data: Data, forSession id: ProteusSessionID) async throws -> Data
    func encryptBatched(data: Data, forSessions sessions: [ProteusSessionID]) async throws -> [String: Data]

    /// Decrypt a proteus message for a given session.
    ///
    /// If a session currently doesn't exist for the session id, a new one
    /// will be established from the encrypted messag.
    ///
    /// - Parameters:
    ///   - data: The encrypted message.
    ///   - id: The id of the session associated with the message.
    ///
    /// - Throws: `ProteusService.DecryptionError`
    /// - Returns: The decrypted data and indicates whether a new session was established.

    func decrypt(
        data: Data,
        forSession id: ProteusSessionID
    ) async throws -> (didCreateNewSession: Bool, decryptedData: Data)

    func generatePrekey(id: UInt16) async throws -> String
    func lastPrekey() async throws -> String
    var lastPrekeyID: UInt16 { get async }
    func generatePrekeys(start: UInt16, count: UInt16) async throws -> [IdPrekeyTuple]
    func localFingerprint() async throws -> String
    func remoteFingerprint(forSession id: ProteusSessionID) async throws -> String
    func fingerprint(fromPrekey prekey: String) async throws -> String
}

public typealias IdPrekeyTuple = (id: UInt16, prekey: String)

// swiftlint:enable orphaned_doc_comment
