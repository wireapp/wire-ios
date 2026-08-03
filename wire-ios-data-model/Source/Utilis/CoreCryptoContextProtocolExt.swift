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

import WireCoreCrypto

// sourcery: AutoMockable
public protocol CoreCryptoContextProtocol: AnyObject, Sendable {

    /// Adds members to the conversation using their key packages, sending the resulting commit via the transport.
    func addClientsToConversation(
        conversationId: WireCoreCryptoUniffi.ConversationId,
        keyPackages: [WireCoreCryptoUniffi.KeyPackage]
    ) async throws

    /// Adds a `Credential` to this client.
    ///
    /// Note that while an arbitrary number of credentials can be generated,
    /// those which are added to a CoreCrypto instance must be distinct in credential type,
    /// signature scheme, and the timestamp of creation. This timestamp has only
    /// 1 second of resolution, limiting the number of credentials which
    /// can be added. This is a known limitation and will be relaxed in the future.
    func addCredential(credential: WireCoreCryptoUniffi.Credential) async throws -> WireCoreCryptoUniffi.CredentialRef

    /// Check all X509 credentials for expiration and revocation
    ///
    /// This function must be called at least once every 24 hours. It is recommended to do this during an idle period,
    /// because in case x509 credentials are used, HTTP requests are done to fetch new certificate revocation lists.
    func checkCredentials() async throws

    /// Commits all pending proposals in the conversation, sending the resulting commit via the transport.
    func commitPendingProposals(conversationId: WireCoreCryptoUniffi.ConversationId) async throws

    /// Returns the cipher suite in use for the given conversation.
    func conversationCipherSuite(conversationId: WireCoreCryptoUniffi.ConversationId) async throws
        -> WireCoreCryptoUniffi.CipherSuite

    /// Get the credential ref for the given conversation.
    func conversationCredential(conversationId: WireCoreCryptoUniffi.ConversationId) async throws
        -> WireCoreCryptoUniffi.CredentialRef

    /// Returns the current MLS epoch of the given conversation.
    func conversationEpoch(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> UInt64

    /// Returns true if a conversation with the given id exists in the local state.
    func conversationExists(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> Bool

    /// Creates a new MLS group with the given conversation ID, using the specified credential.
    func createConversation(
        conversationId: WireCoreCryptoUniffi.ConversationId,
        credentialRef: WireCoreCryptoUniffi.CredentialRef,
        externalSender: WireCoreCryptoUniffi.ExternalSender?
    ) async throws

    /// Decrypts an MLS message received in the given conversation.
    /// **Note**: this will discard any local pending operations.
    func decryptMessage(conversationId: WireCoreCryptoUniffi.ConversationId, payload: Data) async throws
        -> WireCoreCryptoUniffi.DecryptedMessage

    /// Disables history sharing for the given conversation.
    func disableHistorySharing(conversationId: WireCoreCryptoUniffi.ConversationId) async throws

    /// Returns the end-to-end identity verification state of the given conversation.
    func e2eiConversationState(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi
        .E2eiConversationState

    /// Returns true if end-to-end identity is enabled for the given cipher_suite.
    func e2eiIsEnabled(cipherSuite: WireCoreCryptoUniffi.CipherSuite) async throws -> Bool

    /// Enables history sharing for the given conversation.
    func enableHistorySharing(conversationId: WireCoreCryptoUniffi.ConversationId) async throws

    /// Encrypts a plaintext message for all members of the given conversation.
    func encryptMessage(conversationId: WireCoreCryptoUniffi.ConversationId, message: Data) async throws -> Data

    /// Derives and exports a secret of `key_length` bytes for the given conversation.
    ///
    /// The secret is derived from the MLS key schedule's exporter mechanism (RFC 9420 §8.5),
    /// which produces output bound to the current group state and epoch. The exported value
    /// changes whenever the epoch advances.
    func exportSecretKey(conversationId: WireCoreCryptoUniffi.ConversationId, keyLength: UInt32) async throws
        -> WireCoreCryptoUniffi.SecretKey

    /// Generate a `KeyPackage` from the referenced credential.
    ///
    /// Makes no attempt to look up or prune existing keypackages.
    ///
    /// If `lifetime` is set, the keypackages will expire that span into the future.
    /// If it is unset, a default lifetime of approximately 3 months is used.
    func generateKeyPackage(credentialRef: WireCoreCryptoUniffi.CredentialRef, lifetime: TimeInterval?) async throws
        -> WireCoreCryptoUniffi.KeyPackage

    /// Returns the client ids of all members of the given conversation.
    func getClientIds(conversationId: WireCoreCryptoUniffi.ConversationId) async throws
        -> [WireCoreCryptoUniffi.ClientId]

    /// Returns data previously stored by `set_data`, or `None` if no data has been stored.
    func getData() async throws -> Data?

    /// Returns the E2EI identity claims for the specified devices in the given conversation.
    func getDeviceIdentities(
        conversationId: WireCoreCryptoUniffi.ConversationId,
        deviceIds: [WireCoreCryptoUniffi.ClientId]
    ) async throws -> [WireCoreCryptoUniffi.WireIdentity]

    /// Returns the serialized public key of the external sender for the given conversation.
    func getExternalSender(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi
        .ExternalSender

    /// Get a reference to each `KeyPackage` in the database.
    func getKeyPackages() async throws -> [WireCoreCryptoUniffi.KeyPackageRef]

    /// Returns the E2EI identity claims for the specified users in the given conversation, grouped by user ID.
    func getUserIdentities(
        conversationId: WireCoreCryptoUniffi.ConversationId,
        userIds: [WireCoreCryptoUniffi.Uuid]
    ) async throws -> [WireCoreCryptoUniffi.Uuid: [WireCoreCryptoUniffi.WireIdentity]]

    /// Joins an existing conversation by constructing an external commit from the given group info.
    func joinByExternalCommit(
        groupInfo: WireCoreCryptoUniffi.GroupInfo,
        credentialRef: WireCoreCryptoUniffi.CredentialRef
    ) async throws -> WireCoreCryptoUniffi.ConversationId

    /// Initializes the MLS client with the given client ID and message transport.
    ///
    /// In general this method should be called at most once per core-crypto instance.
    /// Calling it multiple times with the same parameters should silently succeed, but this is not
    /// a supported or tested mode of operation.
    /// Calling it multiple times with varying parameters might succeed, but this is not a supported or tested mode of
    /// operation.
    func mlsInit(clientId: WireCoreCryptoUniffi.ClientId, transport: any WireCoreCryptoUniffi.MlsTransport) async throws

    /// Joins a conversation by processing an MLS Welcome message, returning the new conversation's ID.
    func processWelcomeMessage(welcomeMessage: WireCoreCryptoUniffi.Welcome) async throws -> WireCoreCryptoUniffi
        .ConversationId

    /// Decrypts a Proteus ciphertext in the given session, returning the plaintext.
    func proteusDecrypt(sessionId: String, ciphertext: Data) async throws -> Data

    /// Decrypt a message whether or not the proteus session already exists, and saves the session.
    ///
    /// This is intended to replace simple usages of `proteusDecrypt`.
    ///
    /// However, when decrypting large numbers of messages in a single session, the existing methods
    /// may be more efficient.
    func proteusDecryptSafe(sessionId: String, ciphertext: Data) async throws -> Data

    /// Encrypts a plaintext message in the given Proteus session.
    func proteusEncrypt(sessionId: String, plaintext: Data) async throws -> Data

    /// Encrypts a plaintext message in multiple Proteus sessions, returning a map from session ID to ciphertext.
    func proteusEncryptBatched(sessions: [String], plaintext: Data) async throws -> [String: Data]

    /// Returns the hex-encoded public key fingerprint of this device's Proteus identity.
    func proteusFingerprint() async throws -> String

    /// Returns the hex-encoded local public key fingerprint for the Proteus session with the given ID.
    func proteusFingerprintLocal(sessionId: String) async throws -> String

    /// Returns the hex-encoded remote public key fingerprint for the Proteus session with the given ID.
    func proteusFingerprintRemote(sessionId: String) async throws -> String

    /// Initializes the Proteus client.
    ///
    /// In general this method should be called at most once per core-crypto instance.
    /// Calling it multiple times with the same parameters should silently succeed, but this is not
    /// a supported or tested mode of operation.
    /// Calling it multiple times with varying parameters might succeed, but this is not a supported or tested mode of
    /// operation.
    func proteusInit() async throws

    /// Returns the CBOR-serialized last resort prekey bundle, creating it if it does not yet exist.
    func proteusLastResortPrekey() async throws -> Data

    /// Creates a new Proteus prekey with the given ID and returns its CBOR-serialized bundle.
    ///
    /// Warning: the Proteus client must be initialized with `proteus_init` first or an error will be returned.
    func proteusNewPrekey(prekeyId: UInt16) async throws -> Data

    /// Creates a new Proteus prekey with an automatically assigned ID and returns its CBOR-serialized bundle.
    ///
    /// Warning: the Proteus client must be initialized with `proteus_init` first or an error will be returned.
    func proteusNewPrekeyAuto() async throws -> WireCoreCryptoUniffi.ProteusAutoPrekeyBundle

    /// Deletes the Proteus session with the given ID from local storage.
    func proteusSessionDelete(sessionId: String) async throws

    /// Returns true if a Proteus session with the given ID exists in local storage.
    func proteusSessionExists(sessionId: String) async throws -> Bool

    /// Creates a new Proteus session from an incoming encrypted message, returning the decrypted message payload.
    func proteusSessionFromMessage(sessionId: String, envelope: Data) async throws -> Data

    /// Creates a new Proteus session from the given prekey bundle bytes, stored under the given session ID.
    func proteusSessionFromPrekey(sessionId: String, prekey: Data) async throws

    /// Saves the Proteus session with the given ID to the keystore.
    ///
    /// Note: this is not usually needed, as sessions are persisted automatically when
    /// decrypting or encrypting messages and when initializing sessions.
    func proteusSessionSave(sessionId: String) async throws

    /// Generates `len` random bytes from the cryptographically secure RNG.
    func randomBytes(len: UInt32) async throws -> Data

    /// Removes the specified clients from the conversation, sending the resulting commit via the transport.
    func removeClientsFromConversation(
        conversationId: WireCoreCryptoUniffi.ConversationId,
        clients: [WireCoreCryptoUniffi.ClientId]
    ) async throws

    /// Removes a `Credential` from this client.
    func removeCredential(credentialRef: WireCoreCryptoUniffi.CredentialRef) async throws

    /// Remove a `KeyPackage` from the database.
    func removeKeyPackage(kpRef: WireCoreCryptoUniffi.KeyPackageRef) async throws

    /// Remove all `KeyPackage`s associated with this credential ref.
    func removeKeyPackagesFor(credentialRef: WireCoreCryptoUniffi.CredentialRef) async throws

    /// Set the credential ref for the given conversation.
    func setConversationCredential(
        conversationId: WireCoreCryptoUniffi.ConversationId,
        credentialRef: WireCoreCryptoUniffi.CredentialRef
    ) async throws

    /// Stores arbitrary data to be used as a transaction checkpoint.
    ///
    /// The stored data can be retrieved via `get_data`. Keep the data size reasonable;
    /// this is not a general-purpose key-value store.
    func setData(data: Data) async throws

    /// Updates this client's key material in the conversation by sending an update commit.
    func updateKeyingMaterial(conversationId: WireCoreCryptoUniffi.ConversationId) async throws

    /// Destroys the local state of the given conversation; it can no longer be used locally after this call.
    func wipeConversation(conversationId: WireCoreCryptoUniffi.ConversationId) async throws
}
