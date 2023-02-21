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

import Foundation
import CoreCryptoSwift

protocol CoreCryptoInterface {

    /// Almost identical to ```CoreCrypto/init``` but allows a 2 phase initialization of MLS.First, calling this will
    /// set up the keystore and will allow generating proteus prekeys.Then, those keys can be traded for a clientId.
    /// Use this clientId to initialize MLS with ```CoreCrypto/mlsInit```.
    static func deferredInit(path: String, key: String, entropySeed: [UInt8]?) throws -> CoreCryptoSwift.CoreCrypto

    /// Use this after ```CoreCrypto/deferredInit``` when you have a clientId. It initializes MLS.
    ///
    /// - parameter clientId: client identifier
    func mlsInit(clientId: ClientId) throws

    /// Generates a MLS KeyPair/CredentialBundle with a temporary, random client ID.
    /// This method is designed to be used in conjunction with ```CoreCrypto/mlsInitWithClientId``` and represents the first step in this process
    ///
    /// - returns: the TLS-serialized identity key (i.e. the signature keypair's public key)
    func mlsGenerateKeypair() throws -> [UInt8]

    /// Updates the current temporary Client ID with the newly provided one. This is the second step in the externally-generated clients process
    ///
    /// Important: This is designed to be called after ```CoreCrypto/mlsGenerateKeypair```
    ///
    /// - parameter clientId: The newly allocated Client ID from the MLS Authentication Service
    /// - parameter signaturePublicKey: The public key you obtained at step 1, for authentication purposes
    func mlsInitWithClientId(clientId: ClientId, signaturePublicKey: [UInt8]) throws

    /// `CoreCrypto` is supposed to be a singleton. Knowing that, it does some optimizations by
    /// keeping MLS groups in memory. Sometimes, especially on iOS, it is required to use extensions
    /// to perform tasks in the background. Extensions are executed in another process so another
    /// `CoreCrypto` instance has to be used. This method has to be used to synchronize instances.
    /// It simply fetches the MLS group from keystore in memory.
    func restoreFromDisk() throws

    /// Sets the callback interface, required by some operations from `CoreCrypto`
    ///
    /// - parameter callbacks: the object that implements the ``CoreCryptoCallbacks`` interface
    func setCallbacks(callbacks: CoreCryptoSwift.CoreCryptoCallbacks) throws

    /// - returns: The client's public key
    func clientPublicKey() throws -> [UInt8]

    /// Fetches a requested amount of keypackages
    /// - parameter amountRequested: The amount of keypackages requested
    /// - returns: An array of length `amountRequested` containing TLS-serialized KeyPackages
    func clientKeypackages(amountRequested: UInt32) throws -> [[UInt8]]

    /// - returns: The amount of valid, non-expired KeyPackages that are persisted in the backing storage
    func clientValidKeypackagesCount() throws -> UInt64

    /// Creates a new conversation with the current client being the sole member
    /// You will want to use ``addClientsToConversation(conversationId:clients:)`` afterwards to add clients to this conversation
    /// - parameter conversationId: conversation identifier
    /// - parameter config: the configuration for the conversation to be created
    func createConversation(conversationId: ConversationId, config: ConversationConfiguration) throws

    /// Checks if the Client is member of a given conversation and if the MLS Group is loaded up
    /// - parameter conversationId: conversation identifier
    /// - returns: Whether the given conversation ID exists
    func conversationExists(conversationId: ConversationId) -> Bool

    /// Returns the epoch of a given conversation id
    /// - parameter conversationId: conversation identifier
    /// - returns: the current epoch of the conversation
    func conversationEpoch(conversationId: ConversationId) throws -> UInt64

    /// Ingest a TLS-serialized MLS welcome message to join a an existing MLS group
    /// - parameter welcomeMessage: - TLS-serialized MLS Welcome message
    /// - parameter config: - configuration of the MLS group
    /// - returns: The conversation ID of the newly joined group. You can use the same ID to decrypt/encrypt messages
    func processWelcomeMessage(welcomeMessage: [UInt8], configuration: CustomConfiguration) throws -> ConversationId

    /// Adds new clients to a conversation, assuming the current client has the right to add new clients to the conversation
    ///
    /// The returned ``CommitBundle`` is a TLS struct that needs to be fanned out to Delivery Service in order to validate the commit.
    /// It also contains a Welcome message the Delivery Service will forward to invited clients and
    /// an updated PublicGroupState required by clients willing to join the group by an external commit.
    ///
    /// **CAUTION**: ``CoreCryptoWrapper/commitAccepted`` **HAS TO** be called afterwards **ONLY IF** the Delivery Service responds
    /// '200 OK' to the ``CommitBundle`` upload. It will "merge" the commit locally i.e. increment the local group
    /// epoch, use new encryption secrets etc...
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter clients: Array of ``Invitee`` (which are Client ID / KeyPackage pairs)
    /// - returns: A ``CommitBundle`` byte array to fan out to the Delivery Service
    func addClientsToConversation(conversationId: ConversationId, clients: [Invitee]) throws -> MemberAddedMessages

    /// Removes the provided clients from a conversation; Assuming those clients exist and the current client is allowed
    /// to do so, otherwise this operation does nothing.
    ///
    /// The returned ``CommitBundle`` is a TLS struct that needs to be fanned out to Delivery Service in order to validate the commit.
    /// It also contains a Welcome message the Delivery Service will forward to invited clients and
    /// an updated PublicGroupState required by clients willing to join the group by an external commit.
    ///
    /// **CAUTION**: ``CoreCryptoWrapper/commitAccepted`` **HAS TO** be called afterwards **ONLY IF** the Delivery Service responds
    /// '200 OK' to the ``CommitBundle`` upload. It will "merge" the commit locally i.e. increment the local group
    /// epoch, use new encryption secrets etc...
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter clients: Array of Client IDs to remove.
    /// - returns: A ``CommitBundle`` byte array to fan out to the Delivery Service
    func removeClientsFromConversation(conversationId: ConversationId, clients: [ClientId]) throws -> CommitBundle

    /// Self updates the KeyPackage and automatically commits. Pending proposals will be commited.
    ///
    /// The returned ``CommitBundle`` is a TLS struct that needs to be fanned out to Delivery Service in order to validate the commit.
    /// It also contains a Welcome message the Delivery Service will forward to invited clients and
    /// an updated PublicGroupState required by clients willing to join the group by an external commit.
    ///
    /// **CAUTION**: ``CoreCryptoWrapper/commitAccepted`` **HAS TO** be called afterwards **ONLY IF** the Delivery Service responds
    /// '200 OK' to the ``CommitBundle`` upload. It will "merge" the commit locally i.e. increment the local group
    /// epoch, use new encryption secrets etc...
    ///
    /// - parameter conversationId: conversation identifier
    /// - returns: A ``CommitBundle`` byte array to fan out to the Delivery Service
    func updateKeyingMaterial(conversationId: ConversationId) throws -> CommitBundle

    /// Commits all pending proposals of the group
    ///
    /// The returned ``CommitBundle`` is a TLS struct that needs to be fanned out to Delivery Service in order to validate the commit.
    /// It also contains a Welcome message the Delivery Service will forward to invited clients and
    /// an updated PublicGroupState required by clients willing to join the group by an external commit.
    ///
    /// **CAUTION**: ``CoreCryptoWrapper/commitAccepted`` **HAS TO** be called afterwards **ONLY IF** the Delivery Service responds
    /// '200 OK' to the ``CommitBundle`` upload. It will "merge" the commit locally i.e. increment the local group
    /// epoch, use new encryption secrets etc...
    ///
    /// - parameter conversationId: conversation identifier
    /// - returns: A ``CommitBundle`` byte array to fan out to the Delivery Service
    func commitPendingProposals(conversationId: ConversationId) throws -> CommitBundle?

    /// Destroys a group locally
    ///
    /// - parameter conversationId: conversation identifier
    func wipeConversation(conversationId: ConversationId) throws

    /// Deserializes a TLS-serialized message, then deciphers it
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter payload: the encrypted message as a byte array
    /// - returns an object of the type ``DecryptedMessage``
    func decryptMessage(conversationId: ConversationId, payload: [UInt8]) throws -> DecryptedMessage

    /// Encrypts a raw payload then serializes it to the TLS wire format
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter message: the message as a byte array
    /// - returns: an encrypted TLS serialized message.
    func encryptMessage(conversationId: ConversationId, message: [UInt8]) throws -> [UInt8]

    /// Creates a new add proposal within a group
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter keyPackage: the owner's `KeyPackage` to be added to the group
    /// - returns: a message (to be fanned out) will be returned with the proposal that was created
    func newAddProposal(conversationId: ConversationId, keyPackage: [UInt8]) throws -> ProposalBundle

    /// Creates a new update proposal within a group. It will replace the sender's `LeafNode` in the
    /// ratchet tree
    ///
    /// - parameter conversationId: conversation identifier
    /// - returns: a message (to be fanned out) will be returned with the proposal that was created
    func newUpdateProposal(conversationId: ConversationId) throws -> ProposalBundle

    /// Creates a new remove proposal within a group
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter clientId: client id to be removed from the group
    /// - returns: a message (to be fanned out) will be returned with the proposal that was created
    func newRemoveProposal(conversationId: ConversationId, clientId: ClientId) throws -> ProposalBundle

    /// Crafts a new external Add proposal. Enables a client outside a group to request addition to this group.
    /// For Wire only, the client must belong to an user already in the group
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter epoch: the current epoch of the group
    /// - returns: a message with the proposal to be add a new client
    func newExternalAddProposal(conversationId: ConversationId, epoch: UInt64) throws -> [UInt8]

    /// Crafts a new external Remove proposal. Enables a client outside a group to request removal
    /// of a client within the group.
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter epoch: the current epoch of the group
    /// - parameter keyPackageRef: the `KeyPackageRef` of the client to be added to the group
    /// - returns: a message with the proposal to be remove a client
    func newExternalRemoveProposal(conversationId: ConversationId, epoch: UInt64, keyPackageRef: [UInt8]) throws -> [UInt8]

    /// Issues an external commit and stores the group in a temporary table. This method is
    /// intended for example when a new client wants to join the user's existing groups.
    ///
    /// If the Delivery Service accepts the external commit, you have to ``CoreCryptoWrapper/mergePendingGroupFromExternalCommit``
    /// in order to get back a functional MLS group. On the opposite, if it rejects it, you can either retry by just
    /// calling again ``CoreCryptoWrapper/joinByExternalCommit``, no need to ``CoreCryptoWrapper/clearPendingGroupFromExternalCommit``.
    /// If you want to abort the operation (too many retries or the user decided to abort), you can use
    /// ``CoreCryptoWrapper/clearPendingGroupFromExternalCommit`` in order not to bloat the user's storage but nothing
    /// bad can happen if you forget to except some storage space wasted.
    ///
    /// - parameter publicGroupState: a TLS encoded `PublicGroupState` fetched from the Delivery Service
    /// - parameter config: - configuration of the MLS group
    /// - returns: an object of type `ConversationInitBundle`
    func joinByExternalCommit(publicGroupState: [UInt8], configuration: CustomConfiguration) throws -> ConversationInitBundle

    /// Exports a TLS-serialized view of the current group state corresponding to the provided conversation ID.
    ///
    /// - parameter conversationId: conversation identifier
    /// - returns: a TLS serialized byte array of the conversation state
    func exportGroupState(conversationId: ConversationId) throws -> [UInt8]

    /// This merges the commit generated by ``CoreCryptoWrapper/joinByExternalCommit``, persists the group permanently and
    /// deletes the temporary one. After merging, the group should be fully functional.
    ///
    /// - parameter conversationId: conversation identifier
    func mergePendingGroupFromExternalCommit(conversationId: ConversationId) throws

    /// In case the external commit generated by ``CoreCryptoWrapper/joinByExternalCommit`` is rejected by the Delivery Service,
    /// and we want to abort this external commit once for all, we can wipe out the pending group from the keystore in
    /// order not to waste space
    ///
    /// - parameter conversationId: conversation identifier
    func clearPendingGroupFromExternalCommit(conversationId: ConversationId) throws

    /// Derives a new key from the group
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter keyLength: the length of the key to be derived. If the value is higher than the
    /// bounds of `u16` or the context hash * 255, an error will be thrown
    /// - returns a byte array representing the derived key
    func exportSecretKey(conversationId: ConversationId, keyLength: UInt32) throws -> [UInt8]

    /// Returns all clients from group's members
    ///
    /// - parameter conversationId: conversation identifier
    /// - returns a list of `ClientId` objects
    func getClientIds(conversationId: ConversationId) throws -> [ClientId]

    /// Allows ``CoreCrypto`` to act as a CSPRNG provider
    /// - parameter length: The number of bytes to be returned in the `Uint8` array
    /// - returns: A ``Uint8`` array buffer that contains ``length`` cryptographically-secure random bytes
    func randomBytes(length: UInt32) throws -> [UInt8]

    /// Allows to reseed ``CoreCrypto``'s internal CSPRNG with a new seed.
    /// - parameter seed: **exactly 32** bytes buffer seed
    func reseedRng(seed: [UInt8]) throws

    /// The commit we created has been accepted by the Delivery Service. Hence it is guaranteed
    /// to be used for the new epoch.
    /// We can now safely "merge" it (effectively apply the commit to the group) and update it
    /// in the keystore. The previous can be discarded to respect Forward Secrecy.
    ///
    /// - parameter conversationId: conversation identifier
    func commitAccepted(conversationId: ConversationId) throws

    /// Allows to remove a pending (uncommitted) proposal. Use this when backend rejects the proposal
    /// you just sent e.g. if permissions have changed meanwhile.
    ///
    /// **CAUTION**: only use this when you had an explicit response from the Delivery Service
    /// e.g. 403 or 409. Do not use otherwise e.g. 5xx responses, timeout etc..
    ///
    /// - parameter conversation_id - the group/conversation id
    /// - parameter proposal_ref - unique proposal identifier which is present in MlsProposalBundle and
    /// returned from all operation creating a proposal
    func clearPendingProposal(conversationId: ConversationId, proposalRef: [UInt8]) throws

    /// Allows to remove a pending commit. Use this when backend rejects the commit
    /// you just sent e.g. if permissions have changed meanwhile.
    ///
    /// **CAUTION**: only use this when you had an explicit response from the Delivery Service
    /// e.g. 403. Do not use otherwise e.g. 5xx responses, timeout etc..
    /// **DO NOT** use when Delivery Service responds 409, pending state will be renewed
    /// in [MlsCentral::decrypt_message]
    ///
    /// - parameter conversation_id - the group/conversation id
    func clearPendingCommit(conversationId: ConversationId) throws

    /// Initiailizes the proteus client
    func proteusInit() throws

    /// Create a Proteus session using a prekey
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - parameter prekey: CBOR-encoded Proteus prekey of the other client
    func proteusSessionFromPrekey(sessionId: String, prekey: [UInt8]) throws

    /// Create a Proteus session from a handshake message
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - parameter envelope: CBOR-encoded Proteus message
    func proteusSessionFromMessage(sessionId: String, envelope: [UInt8]) throws -> [UInt8]

    /// Locally persists a session to the keystore
    ///
    /// - parameter sessionId: ID of the Proteus session
    func proteusSessionSave(sessionId: String) throws

    /// Deletes a session
    /// Note: this also deletes the persisted data within the keystore
    ///
    /// - parameter sessionId: ID of the Proteus session
    func proteusSessionDelete(sessionId: String) throws

    /// Checks if a session exists
    ///
    /// - parameter sessionId: ID of the Proteus session
    func proteusSessionExists(sessionId: String) throws -> Bool

    /// Decrypt an incoming message for an existing Proteus session
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - parameter ciphertext: CBOR encoded, encrypted proteus message
    /// - returns: The decrypted payload contained within the message
    func proteusDecrypt(sessionId: String, ciphertext: [UInt8]) throws -> [UInt8]

    /// Encrypt a message for a given Proteus session
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - parameter plaintext: payload to encrypt
    /// - returns: The CBOR-serialized encrypted message
    func proteusEncrypt(sessionId: String, plaintext: [UInt8]) throws -> [UInt8]

    /// Batch encryption for proteus messages
    /// This is used to minimize FFI roundtrips when used in the context of a multi-client session (i.e. conversation)
    ///
    /// - parameter sessions: List of Proteus session IDs to encrypt the message for
    /// - parameter plaintext: payload to encrypt
    /// - returns: A map indexed by each session ID and the corresponding CBOR-serialized encrypted message for this session
    func proteusEncryptBatched(sessions: [String], plaintext: [UInt8]) throws -> [String: [UInt8]]

    /// Creates a new prekey with the requested ID.
    ///
    /// - parameter prekeyId: ID of the PreKey to generate
    /// - returns: A CBOR-serialized version of the PreKeyBundle corresponding to the newly generated and stored PreKey
    func proteusNewPrekey(prekeyId: UInt16) throws -> [UInt8]

    /// Creates a new prekey with an automatically incremented ID.
    ///
    /// - returns: A CBOR-serialized version of the PreKeyBundle corresponding to the newly generated and stored PreKey
    func proteusNewPrekeyAuto() throws -> [UInt8]

    /// - returns: A CBOR-serialized verison of the PreKeyBundle associated to the last resort prekey ID
    func proteusLastResortPrekey() throws -> [UInt8]

    /// - returns: The ID of the Proteus last resort PreKey
    func proteusLastResortPrekeyId() throws -> UInt16

    /// Proteus public key fingerprint
    /// It's basically the public key encoded as an hex string
    ///
    /// - returns: Hex-encoded public key string
    func proteusFingerprint() throws -> String


    /// Proteus session local fingerprint
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - returns: Hex-encoded public key string
    func proteusFingerprintLocal(sessionId: String) throws -> String

    /// Proteus session remote fingerprint
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - returns: Hex-encoded public key string
    func proteusFingerprintRemote(sessionId: String) throws -> String

    /// Hex-encoded fingerprint of the given prekey
    ///
    /// - parameter prekey: the prekey bundle to get the fingerprint from
    /// - returns: Hex-encoded public key string
    func proteusFingerprintPrekeybundle(prekey: [UInt8]) throws -> String

     /// Imports all the data stored by Cryptobox into the CoreCrypto keystore
     ///
     /// @param path - Path to the folder where Cryptobox things are stored
    func proteusCryptoboxMigrate(path: String) throws
}
