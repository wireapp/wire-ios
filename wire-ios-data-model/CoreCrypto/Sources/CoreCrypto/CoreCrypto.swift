// Wire
// Copyright (C) 2022 Wire Swiss GmbH

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.

import CoreCryptoSwift
import Foundation

/// Interface to convert to ``CoreCrypto``'s internal types
private protocol ConvertToInner {
    associatedtype Inner
    func convert() -> Inner
}

extension CoreCryptoSwift.CommitBundle {
    func convertTo() -> CommitBundle {
        return CommitBundle(welcome: self.welcome, commit: self.commit, publicGroupState: self.publicGroupState.convertTo())
    }
}

extension CoreCryptoSwift.MemberAddedMessages {
    func convertTo() -> MemberAddedMessages {
        return MemberAddedMessages(commit: self.commit, welcome: self.welcome, publicGroupState: self.publicGroupState.convertTo())
    }
}

extension CoreCryptoSwift.ConversationInitBundle {
    func convertTo() -> ConversationInitBundle {
        return ConversationInitBundle(conversationId: self.conversationId, commit: self.commit, publicGroupState: self.publicGroupState.convertTo())
    }
}

extension CoreCryptoSwift.DecryptedMessage {
    func convertTo() -> DecryptedMessage {
        return DecryptedMessage(message: self.message, proposals: self.proposals.map({ (bundle) -> ProposalBundle in
            return bundle.convertTo()
        }), isActive: self.isActive, commitDelay: self.commitDelay, senderClientId: self.senderClientId, hasEpochChanged: self.hasEpochChanged)
    }
}

extension CoreCryptoSwift.ProposalBundle {
    func convertTo() -> ProposalBundle {
        return ProposalBundle(proposal: self.proposal, proposalRef: self.proposalRef)
    }
}

extension CoreCryptoSwift.PublicGroupStateBundle {
    func convertTo() -> PublicGroupStateBundle {
        return PublicGroupStateBundle(encryptionType: self.encryptionType.convertTo(), ratchetTreeType: self.ratchetTreeType.convertTo(), payload: self.payload)
    }
}

extension CoreCryptoSwift.MlsPublicGroupStateEncryptionType {
    func convertTo() -> PublicGroupStateEncryptionType {
        switch self {
            case .jweEncrypted: return PublicGroupStateEncryptionType.JweEncrypted
            case .plaintext: return PublicGroupStateEncryptionType.Plaintext
        }
    }
}

extension CoreCryptoSwift.ProteusAutoPrekeyBundle {
    func convertTo() -> ProteusAutoPrekeyBundle {
        return ProteusAutoPrekeyBundle(id: self.id, pkb: self.pkb)
    }
}

extension CoreCryptoSwift.MlsRatchetTreeType {
    func convertTo() -> RatchetTreeType {
        switch self {
            case .full: return RatchetTreeType.Full
            case .delta: return RatchetTreeType.Delta
            case .byRef: return RatchetTreeType.ByRef
        }
    }
}

/// Alias for conversation IDs.
/// This is a freeform, uninspected buffer.
public typealias ConversationId = [UInt8]

/// Alias for ClientId within a conversation.
public typealias ClientId = [UInt8]

/// Conversation ciphersuite variants
public enum CiphersuiteName: ConvertToInner {
    typealias Inner = CoreCryptoSwift.CiphersuiteName

    case mls128Dhkemx25519Aes128gcmSha256Ed25519
    case mls128Dhkemp256Aes128gcmSha256P256
    case mls128Dhkemx25519Chacha20poly1305Sha256Ed25519
    case mls256Dhkemx448Aes256gcmSha512Ed448
    case mls256Dhkemp521Aes256gcmSha512P521
    case mls256Dhkemx448Chacha20poly1305Sha512Ed448
    case mls256Dhkemp384Aes256gcmSha384P384
}

private extension CiphersuiteName {
    func convert() -> Inner {
        switch self {
        case .mls128Dhkemx25519Aes128gcmSha256Ed25519:
            return CoreCryptoSwift.CiphersuiteName.mls128Dhkemx25519Aes128gcmSha256Ed25519
        case .mls128Dhkemp256Aes128gcmSha256P256:
            return CoreCryptoSwift.CiphersuiteName.mls128Dhkemp256Aes128gcmSha256P256
        case .mls128Dhkemx25519Chacha20poly1305Sha256Ed25519:
            return CoreCryptoSwift.CiphersuiteName.mls128Dhkemx25519Chacha20poly1305Sha256Ed25519
        case .mls256Dhkemx448Aes256gcmSha512Ed448:
            return CoreCryptoSwift.CiphersuiteName.mls256Dhkemx448Aes256gcmSha512Ed448
        case .mls256Dhkemp521Aes256gcmSha512P521:
            return CoreCryptoSwift.CiphersuiteName.mls256Dhkemp521Aes256gcmSha512P521
        case .mls256Dhkemx448Chacha20poly1305Sha512Ed448:
            return CoreCryptoSwift.CiphersuiteName.mls256Dhkemx448Chacha20poly1305Sha512Ed448
        case .mls256Dhkemp384Aes256gcmSha384P384:
            return CoreCryptoSwift.CiphersuiteName.mls256Dhkemp384Aes256gcmSha384P384
        }
    }
}

public struct ProteusAutoPrekeyBundle: ConvertToInner {
    typealias Inner = CoreCryptoSwift.ProteusAutoPrekeyBundle
    func convert() -> Inner {
        return CoreCryptoSwift.ProteusAutoPrekeyBundle(id: self.id, pkb: self.preKeyBundle)
    }

    /// Proteus PreKey ID
    public var id: UInt16
    /// CBOR-serialized Proteus PreKeyBundle
    public var preKeyBundle: [UInt8]

    public init(id: UInt16, pkb: [UInt8]) {
        self.id = id
        self.preKeyBundle = pkb
    }
}

/// Configuration object for new conversations
public struct ConversationConfiguration: ConvertToInner {
    typealias Inner = CoreCryptoSwift.ConversationConfiguration
    func convert() -> Inner {
        return CoreCryptoSwift.ConversationConfiguration(ciphersuite: self.ciphersuite?.convert(), externalSenders: self.externalSenders, custom: self.custom.convert())
    }

    /// Conversation ciphersuite
    public var ciphersuite: CiphersuiteName?
    /// List of client IDs that are allowed to be external senders of commits
    public var externalSenders: [[UInt8]]
    /// Implementation specific configuration
    public var custom: CustomConfiguration

    public init(ciphersuite: CiphersuiteName?, externalSenders: [[UInt8]], custom: CustomConfiguration) {
        self.ciphersuite = ciphersuite
        self.externalSenders = externalSenders
        self.custom = custom
    }
}

/// Defines if handshake messages are encrypted or not
public enum WirePolicy: ConvertToInner {
    typealias Inner = CoreCryptoSwift.MlsWirePolicy

    case plaintext
    case ciphertext
}

private extension WirePolicy {
    func convert() -> Inner {
        switch self {
        case .plaintext:
            return CoreCryptoSwift.MlsWirePolicy.plaintext
        case .ciphertext:
            return CoreCryptoSwift.MlsWirePolicy.ciphertext
        }
    }
}

/// Implementation specific configuration object for a conversation
public struct CustomConfiguration: ConvertToInner {
    typealias Inner = CoreCryptoSwift.CustomConfiguration
    func convert() -> Inner {
        return CoreCryptoSwift.CustomConfiguration(keyRotationSpan: self.keyRotationSpan, wirePolicy: self.wirePolicy?.convert())
    }

    /// Duration in seconds after which we will automatically force a self_update commit
    /// Note: This isn't currently implemented
    public var keyRotationSpan: TimeInterval?
    /// Defines if handshake messages are encrypted or not
    /// Note: Ciphertext is not currently supported by wire-server
    public var wirePolicy: WirePolicy?

    public init(keyRotationSpan: TimeInterval?, wirePolicy: WirePolicy?) {
        self.keyRotationSpan = keyRotationSpan
        self.wirePolicy = wirePolicy
    }
}

/// Data shape for adding clients to a conversation
public struct Invitee: ConvertToInner {
    typealias Inner = CoreCryptoSwift.Invitee
    /// Client ID as a byte array
    public var id: ClientId
    /// MLS KeyPackage belonging to the aforementioned client
    public var kp: [UInt8]

    public init(id: ClientId, kp: [UInt8]) {
        self.id = id
        self.kp = kp
    }

    func convert() -> Inner {
        return CoreCryptoSwift.Invitee(id: self.id, kp: self.kp)
    }
}

/// Data shape for the returned MLS commit & welcome message tuple upon adding clients to a conversation
public struct MemberAddedMessages: ConvertToInner {
    typealias Inner = CoreCryptoSwift.MemberAddedMessages
    /// TLS-serialized MLS Welcome message that needs to be fanned out to the clients newly added to the conversation
    public var commit: [UInt8]
    /// TLS-serialized MLS Commit that needs to be fanned out to other (existing) members of the conversation
    public var welcome: [UInt8]
    /// The current group state
    public var publicGroupState: PublicGroupStateBundle

    public init(commit: [UInt8], welcome: [UInt8], publicGroupState: PublicGroupStateBundle) {
        self.commit = commit
        self.welcome = welcome
        self.publicGroupState = publicGroupState
    }

    func convert() -> Inner {
        return CoreCryptoSwift.MemberAddedMessages(commit: self.commit, welcome: self.welcome, publicGroupState: self.publicGroupState.convert())
    }
}

/// Represents the potential items a consumer might require after passing us an encrypted message we
/// have decrypted for him
public struct DecryptedMessage: ConvertToInner {
    typealias Inner = CoreCryptoSwift.DecryptedMessage
    /// Decrypted text message
    public var message: [UInt8]?
    /// Only when decrypted message is a commit, CoreCrypto will renew local proposal which could not make it in the commit.
    /// This will contain either:
    /// - local pending proposal not in the accepted commit
    /// - If there is a pending commit, its proposals which are not in the accepted commit
    public var proposals: [ProposalBundle]
    /// Is the conversation still active after receiving this commit
    /// aka has the user been removed from the group
    public var isActive: Bool
    /// delay time in seconds to feed caller timer for committing
    public var commitDelay: UInt64?
    /// Client identifier of the sender of the message being decrypted. Only present for application messages.
    public var senderClientId: ClientId?
    /// It is set to true if the decrypted messages resulted in a epoch change (AKA it was a commit)
    public var hasEpochChanged: Bool

    public init(message: [UInt8]?, proposals: [ProposalBundle], isActive: Bool, commitDelay: UInt64?, senderClientId: ClientId?, hasEpochChanged: Bool) {
        self.message = message
        self.proposals = proposals
        self.isActive = isActive
        self.commitDelay = commitDelay
        self.senderClientId = senderClientId
        self.hasEpochChanged = hasEpochChanged
    }

    func convert() -> Inner {
        return CoreCryptoSwift.DecryptedMessage(message: self.message, proposals: self.proposals.map({ (bundle) -> CoreCryptoSwift.ProposalBundle in
            bundle.convert()
        }), isActive: self.isActive, commitDelay: self.commitDelay, senderClientId: self.senderClientId, hasEpochChanged: self.hasEpochChanged)
    }
}

/// Result of a created commit
public struct ProposalBundle: ConvertToInner {
    typealias Inner = CoreCryptoSwift.ProposalBundle
    /// The proposal message
    public var proposal: [UInt8]
    /// An identifier of the proposal to rollback it later if required
    public var proposalRef: [UInt8]

    public init(proposal: [UInt8], proposalRef: [UInt8]) {
        self.proposal = proposal
        self.proposalRef = proposalRef
    }

    func convert() -> Inner {
        return CoreCryptoSwift.ProposalBundle(proposal: self.proposal, proposalRef: self.proposalRef)
    }
}

/// Represents the result type of the external commit request.
public struct ConversationInitBundle: ConvertToInner {
    typealias Inner = CoreCryptoSwift.ConversationInitBundle
    /// Conversation id
    public var conversationId: ConversationId
    /// TLS-serialized MLS External Commit that needs to be fanned out
    public var commit: [UInt8]
    /// TLS-serialized PublicGroupState (aka GroupInfo) which becomes valid when the external commit is accepted by the Delivery Service
    public var publicGroupState: PublicGroupStateBundle

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(conversationId: ConversationId, commit: [UInt8], publicGroupState: PublicGroupStateBundle) {
        self.conversationId = conversationId
        self.commit = commit
        self.publicGroupState = publicGroupState
    }

    func convert() -> Inner {
        return CoreCryptoSwift.ConversationInitBundle(conversationId: self.conversationId, commit: self.commit, publicGroupState: self.publicGroupState.convert())
    }
}

/// Data shape for a MLS generic commit + optional bundle (aka stapled commit & welcome)
public struct CommitBundle: ConvertToInner {
    /// Optional TLS-serialized MLS Welcome message that needs to be fanned out to the clients newly added to the conversation
    public var welcome: [UInt8]?
    /// TLS-serialized MLS Commit that needs to be fanned out to other (existing) members of the conversation
    public var commit: [UInt8]
    /// The current state of the group
    public var publicGroupState: PublicGroupStateBundle

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(welcome: [UInt8]?, commit: [UInt8], publicGroupState: PublicGroupStateBundle) {
        self.welcome = welcome
        self.commit = commit
        self.publicGroupState = publicGroupState
    }
    typealias Inner = CoreCryptoSwift.CommitBundle

    func convert() -> Inner {
        return CoreCryptoSwift.CommitBundle(welcome: self.welcome, commit: self.commit, publicGroupState: self.publicGroupState.convert())
    }
}

/// A PublicGroupState with metadata
public struct PublicGroupStateBundle: ConvertToInner {
    /// Indicates if the payload is encrypted or not
    public var encryptionType: PublicGroupStateEncryptionType
    /// Indicates if the payload contains a full, partial or referenced PublicGroupState
    public var ratchetTreeType: RatchetTreeType
    /// TLS encoded PublicGroupState
    public var payload: [UInt8]

    public init(encryptionType: PublicGroupStateEncryptionType, ratchetTreeType: RatchetTreeType, payload: [UInt8]) {
        self.encryptionType = encryptionType
        self.ratchetTreeType = ratchetTreeType
        self.payload = payload
    }
    typealias Inner = CoreCryptoSwift.PublicGroupStateBundle

    func convert() -> Inner {
        return CoreCryptoSwift.PublicGroupStateBundle(encryptionType: self.encryptionType.convert(), ratchetTreeType: self.ratchetTreeType.convert(), payload: self.payload)
    }
}

/// In order to guarantee confidentiality of the PublicGroupState on the wire a domain can request it to be encrypted when sent to the Delivery Service.
public enum PublicGroupStateEncryptionType: ConvertToInner {
    typealias Inner = CoreCryptoSwift.MlsPublicGroupStateEncryptionType

    case Plaintext
    case JweEncrypted
}

private extension PublicGroupStateEncryptionType {
    func convert() -> Inner {
        switch self {
        case .Plaintext:
            return CoreCryptoSwift.MlsPublicGroupStateEncryptionType.plaintext
        case .JweEncrypted:
            return CoreCryptoSwift.MlsPublicGroupStateEncryptionType.jweEncrypted
        }
    }
}

/// In order to spare some precious bytes, a PublicGroupState can have different representations.
public enum RatchetTreeType: ConvertToInner {
    typealias Inner = CoreCryptoSwift.MlsRatchetTreeType

    case Full
    case Delta
    case ByRef
}

private extension RatchetTreeType {
    func convert() -> Inner {
        switch self {
        case .Full:
            return CoreCryptoSwift.MlsRatchetTreeType.full
        case .Delta:
            return CoreCryptoSwift.MlsRatchetTreeType.delta
        case .ByRef:
            return CoreCryptoSwift.MlsRatchetTreeType.byRef
        }
    }
}

/// A wrapper for the underlying ``CoreCrypto`` object.
/// Intended to avoid API breakages due to possible changes in the internal framework used to generate it
public class CoreCryptoWrapper {
    fileprivate let coreCrypto: CoreCrypto

    /// This is your entrypoint to initialize ``CoreCrypto``
    /// - parameter path: Name of the IndexedDB database
    /// - parameter key: Encryption master key
    /// - parameter clientId: MLS Client ID.
    /// - parameter entropySeed: External PRNG entropy pool seed.
    ///
    /// # Notes #
    /// 1. ``entropySeed`` **must** be exactly 32 bytes
    /// 2. ``clientId`` should stay consistent as it will be verified against the stored signature & identity to validate the persisted credential
    /// 3. ``key`` should be appropriately stored in a secure location (i.e. WebCrypto private key storage)
    ///
    public init(path: String, key: String, clientId: ClientId, entropySeed: [UInt8]?) throws {
        self.coreCrypto = try CoreCrypto(path: path, key: key, clientId: clientId, entropySeed: entropySeed)
    }

    /// Almost identical to ```CoreCrypto/init``` but allows a 2 phase initialization of MLS.First, calling this will
    /// set up the keystore and will allow generating proteus prekeys.Then, those keys can be traded for a clientId.
    /// Use this clientId to initialize MLS with ```CoreCrypto/mlsInit```.
    public static func deferredInit(path: String, key: String, entropySeed: [UInt8]?) throws -> CoreCrypto {
        try CoreCrypto.deferredInit(path: path, key: key, entropySeed: entropySeed)
    }

    /// Use this after ```CoreCrypto/deferredInit``` when you have a clientId. It initializes MLS.
    ///
    /// - parameter clientId: client identifier
    public func mlsInit(clientId: ClientId) throws {
        try self.coreCrypto.mlsInit(clientId: clientId)
    }

    /// Generates a MLS KeyPair/CredentialBundle with a temporary, random client ID.
    /// This method is designed to be used in conjunction with ```CoreCrypto/mlsInitWithClientId``` and represents the first step in this process
    ///
    /// - returns: the TLS-serialized identity key (i.e. the signature keypair's public key)
    public func mlsGenerateKeypair() throws -> [UInt8] {
        try self.coreCrypto.mlsGenerateKeypair()
    }

    /// Updates the current temporary Client ID with the newly provided one. This is the second step in the externally-generated clients process
    ///
    /// Important: This is designed to be called after ```CoreCrypto/mlsGenerateKeypair```
    ///
    /// - parameter clientId: The newly allocated Client ID from the MLS Authentication Service
    /// - parameter signaturePublicKey: The public key you obtained at step 1, for authentication purposes
    public func mlsInitWithClientId(clientId: ClientId, signaturePublicKey: [UInt8]) throws {
        try self.coreCrypto.mlsInitWithClientId(clientId: clientId, signaturePublicKey: signaturePublicKey)
    }

    /// `CoreCrypto` is supposed to be a singleton. Knowing that, it does some optimizations by
    /// keeping MLS groups in memory. Sometimes, especially on iOS, it is required to use extensions
    /// to perform tasks in the background. Extensions are executed in another process so another
    /// `CoreCrypto` instance has to be used. This method has to be used to synchronize instances.
    /// It simply fetches the MLS group from keystore in memory.
    public func restoreFromDisk() throws {
        return try self.coreCrypto.restoreFromDisk()
    }

    /// Sets the callback interface, required by some operations from `CoreCrypto`
    ///
    /// - parameter callbacks: the object that implements the ``CoreCryptoCallbacks`` interface
    public func setCallbacks(callbacks: CoreCryptoCallbacks) throws {
        try self.coreCrypto.setCallbacks(callbacks: callbacks)
    }

    /// - returns: The client's public key
    public func clientPublicKey() throws -> [UInt8] {
        return try self.coreCrypto.clientPublicKey()
    }

    /// Fetches a requested amount of keypackages
    /// - parameter amountRequested: The amount of keypackages requested
    /// - returns: An array of length `amountRequested` containing TLS-serialized KeyPackages
    public func clientKeypackages(amountRequested: UInt32) throws -> [[UInt8]] {
        return try self.coreCrypto.clientKeypackages(amountRequested: amountRequested)
    }

    /// - returns: The amount of valid, non-expired KeyPackages that are persisted in the backing storage
    public func clientValidKeypackagesCount() throws -> UInt64 {
        return try self.coreCrypto.clientValidKeypackagesCount()
    }

    /// Creates a new conversation with the current client being the sole member
    /// You will want to use ``addClientsToConversation(conversationId:clients:)`` afterwards to add clients to this conversation
    /// - parameter conversationId: conversation identifier
    /// - parameter config: the configuration for the conversation to be created
    public func createConversation(conversationId: ConversationId, config: ConversationConfiguration) throws {
        try self.coreCrypto.createConversation(conversationId: conversationId, config: config.convert())
    }

    /// Checks if the Client is member of a given conversation and if the MLS Group is loaded up
    /// - parameter conversationId: conversation identifier
    /// - returns: Whether the given conversation ID exists
    public func conversationExists(conversationId: ConversationId) -> Bool {
        return self.coreCrypto.conversationExists(conversationId: conversationId)
    }

    /// Returns the epoch of a given conversation id
    /// - parameter conversationId: conversation identifier
    /// - returns: the current epoch of the conversation
    public func conversationEpoch(conversationId: ConversationId) throws -> UInt64 {
        return try self.coreCrypto.conversationEpoch(conversationId: conversationId)
    }

    /// Ingest a TLS-serialized MLS welcome message to join a an existing MLS group
    /// - parameter welcomeMessage: - TLS-serialized MLS Welcome message
    /// - parameter config: - configuration of the MLS group
    /// - returns: The conversation ID of the newly joined group. You can use the same ID to decrypt/encrypt messages
    public func processWelcomeMessage(welcomeMessage: [UInt8], configuration: CustomConfiguration) throws -> ConversationId {
        return try self.coreCrypto.processWelcomeMessage(welcomeMessage: welcomeMessage, customConfiguration: configuration.convert())
    }

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
    public func addClientsToConversation(conversationId: ConversationId, clients: [Invitee]) throws -> MemberAddedMessages {
        return try self.coreCrypto.addClientsToConversation(conversationId: conversationId, clients: clients.map({ (invitee) -> CoreCryptoSwift.Invitee in
            return invitee.convert()
        })).convertTo()
    }

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
    public func removeClientsFromConversation(conversationId: ConversationId, clients: [ClientId]) throws -> CommitBundle {
        return try self.coreCrypto.removeClientsFromConversation(conversationId: conversationId, clients: clients).convertTo()
    }

    /// Marks a conversation as child of another one
    /// This will mostly affect the behavior of the callbacks (the parentConversationClients parameter will be filled)
    ///
    /// - parameter childId: conversation identifier of the child conversation
    /// - parameter parentId: conversation identifier of the parent conversation
    public func markConversationAsChildOf(childId: ConversationId, parentId: ConversationId) throws {
        try self.coreCrypto.markConversationAsChildOf(childId: childId, parentId: parentId)
    }

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
    public func updateKeyingMaterial(conversationId: ConversationId) throws -> CommitBundle {
        try self.coreCrypto.updateKeyingMaterial(conversationId: conversationId).convertTo()
    }

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
    public func commitPendingProposals(conversationId: ConversationId) throws -> CommitBundle? {
        try self.coreCrypto.commitPendingProposals(conversationId:conversationId)?.convertTo()
    }

    /// Destroys a group locally
    ///
    /// - parameter conversationId: conversation identifier
    public func wipeConversation(conversationId: ConversationId) throws {
        try self.coreCrypto.wipeConversation(conversationId: conversationId)
    }

    /// Deserializes a TLS-serialized message, then deciphers it
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter payload: the encrypted message as a byte array
    /// - returns an object of the type ``DecryptedMessage``
    public func decryptMessage(conversationId: ConversationId, payload: [UInt8]) throws -> DecryptedMessage {
        return try self.coreCrypto.decryptMessage(conversationId: conversationId, payload: payload).convertTo()
    }

    /// Encrypts a raw payload then serializes it to the TLS wire format
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter message: the message as a byte array
    /// - returns: an encrypted TLS serialized message.
    public func encryptMessage(conversationId: ConversationId, message: [UInt8]) throws -> [UInt8] {
        return try self.coreCrypto.encryptMessage(conversationId: conversationId, message: message)
    }

    /// Creates a new add proposal within a group
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter keyPackage: the owner's `KeyPackage` to be added to the group
    /// - returns: a message (to be fanned out) will be returned with the proposal that was created
    public func newAddProposal(conversationId: ConversationId, keyPackage: [UInt8]) throws -> ProposalBundle {
        return try self.coreCrypto.newAddProposal(conversationId: conversationId, keyPackage: keyPackage).convertTo()
    }

    /// Creates a new update proposal within a group. It will replace the sender's `LeafNode` in the
    /// ratchet tree
    ///
    /// - parameter conversationId: conversation identifier
    /// - returns: a message (to be fanned out) will be returned with the proposal that was created
    public func newUpdateProposal(conversationId: ConversationId) throws -> ProposalBundle {
        return try self.coreCrypto.newUpdateProposal(conversationId: conversationId).convertTo()
    }

    /// Creates a new remove proposal within a group
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter clientId: client id to be removed from the group
    /// - returns: a message (to be fanned out) will be returned with the proposal that was created
    public func newRemoveProposal(conversationId: ConversationId, clientId: ClientId) throws -> ProposalBundle {
        return try self.coreCrypto.newRemoveProposal(conversationId: conversationId, clientId: clientId).convertTo()
    }

    /// Crafts a new external Add proposal. Enables a client outside a group to request addition to this group.
    /// For Wire only, the client must belong to an user already in the group
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter epoch: the current epoch of the group
    /// - returns: a message with the proposal to be add a new client
    public func newExternalAddProposal(conversationId: ConversationId, epoch: UInt64) throws -> [UInt8] {
        return try self.coreCrypto.newExternalAddProposal(conversationId: conversationId, epoch: epoch)
    }

    /// Crafts a new external Remove proposal. Enables a client outside a group to request removal
    /// of a client within the group.
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter epoch: the current epoch of the group
    /// - parameter keyPackageRef: the `KeyPackageRef` of the client to be added to the group
    /// - returns: a message with the proposal to be remove a client
    public func newExternalRemoveProposal(conversationId: ConversationId, epoch: UInt64, keyPackageRef: [UInt8]) throws -> [UInt8] {
        return try self.coreCrypto.newExternalRemoveProposal(conversationId: conversationId, epoch: epoch, keyPackageRef: keyPackageRef)
    }

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
    public func joinByExternalCommit(publicGroupState: [UInt8], configuration: CustomConfiguration) throws -> ConversationInitBundle {
        try self.coreCrypto.joinByExternalCommit(publicGroupState: publicGroupState, customConfiguration: configuration.convert()).convertTo()
    }

    /// Exports a TLS-serialized view of the current group state corresponding to the provided conversation ID.
    ///
    /// - parameter conversationId: conversation identifier
    /// - returns: a TLS serialized byte array of the conversation state
    public func exportGroupState(conversationId: ConversationId) throws -> [UInt8] {
        return try self.coreCrypto.exportGroupState(conversationId: conversationId)
    }

    /// This merges the commit generated by ``CoreCryptoWrapper/joinByExternalCommit``, persists the group permanently and
    /// deletes the temporary one. After merging, the group should be fully functional.
    ///
    /// - parameter conversationId: conversation identifier
    public func mergePendingGroupFromExternalCommit(conversationId: ConversationId) throws {
        try self.coreCrypto.mergePendingGroupFromExternalCommit(conversationId: conversationId)
    }

    /// In case the external commit generated by ``CoreCryptoWrapper/joinByExternalCommit`` is rejected by the Delivery Service,
    /// and we want to abort this external commit once for all, we can wipe out the pending group from the keystore in
    /// order not to waste space
    ///
    /// - parameter conversationId: conversation identifier
    public func clearPendingGroupFromExternalCommit(conversationId: ConversationId) throws {
        try self.coreCrypto.clearPendingGroupFromExternalCommit(conversationId: conversationId)
    }

    /// Derives a new key from the group
    ///
    /// - parameter conversationId: conversation identifier
    /// - parameter keyLength: the length of the key to be derived. If the value is higher than the
    /// bounds of `u16` or the context hash * 255, an error will be thrown
    /// - returns a byte array representing the derived key
    public func exportSecretKey(conversationId: ConversationId, keyLength: UInt32) throws -> [UInt8] {
        try self.coreCrypto.exportSecretKey(conversationId: conversationId, keyLength: keyLength)
    }

    /// Returns all clients from group's members
    ///
    /// - parameter conversationId: conversation identifier
    /// - returns a list of `ClientId` objects
    public func getClientIds(conversationId: ConversationId) throws -> [ClientId] {
        try self.coreCrypto.getClientIds(conversationId: conversationId)
    }

    /// Allows ``CoreCrypto`` to act as a CSPRNG provider
    /// - parameter length: The number of bytes to be returned in the `Uint8` array
    /// - returns: A ``Uint8`` array buffer that contains ``length`` cryptographically-secure random bytes
    public func randomBytes(length: UInt32) throws -> [UInt8] {
        try self.coreCrypto.randomBytes(length: length)
    }

    /// Allows to reseed ``CoreCrypto``'s internal CSPRNG with a new seed.
    /// - parameter seed: **exactly 32** bytes buffer seed
    public func reseedRng(seed: [UInt8]) throws {
        try self.coreCrypto.reseedRng(seed: seed)
    }

    /// The commit we created has been accepted by the Delivery Service. Hence it is guaranteed
    /// to be used for the new epoch.
    /// We can now safely "merge" it (effectively apply the commit to the group) and update it
    /// in the keystore. The previous can be discarded to respect Forward Secrecy.
    ///
    /// - parameter conversationId: conversation identifier
    public func commitAccepted(conversationId: ConversationId) throws {
        try self.coreCrypto.commitAccepted(conversationId: conversationId)
    }

    /// Allows to remove a pending (uncommitted) proposal. Use this when backend rejects the proposal
    /// you just sent e.g. if permissions have changed meanwhile.
    ///
    /// **CAUTION**: only use this when you had an explicit response from the Delivery Service
    /// e.g. 403 or 409. Do not use otherwise e.g. 5xx responses, timeout etc..
    ///
    /// - parameter conversation_id - the group/conversation id
    /// - parameter proposal_ref - unique proposal identifier which is present in MlsProposalBundle and
    /// returned from all operation creating a proposal
    public func clearPendingProposal(conversationId: ConversationId, proposalRef: [UInt8]) throws {
        try self.coreCrypto.clearPendingProposal(conversationId: conversationId, proposalRef: proposalRef)

    }

    /// Allows to remove a pending commit. Use this when backend rejects the commit
    /// you just sent e.g. if permissions have changed meanwhile.
    ///
    /// **CAUTION**: only use this when you had an explicit response from the Delivery Service
    /// e.g. 403. Do not use otherwise e.g. 5xx responses, timeout etc..
    /// **DO NOT** use when Delivery Service responds 409, pending state will be renewed
    /// in [MlsCentral::decrypt_message]
    ///
    /// - parameter conversation_id - the group/conversation id
    public func clearPendingCommit(conversationId: ConversationId) throws {
        try self.coreCrypto.clearPendingCommit(conversationId: conversationId)
    }

    /// Initiailizes the proteus client
    public func proteusInit() throws {
        try self.coreCrypto.proteusInit()
    }

    /// Create a Proteus session using a prekey
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - parameter prekey: CBOR-encoded Proteus prekey of the other client
    public func proteusSessionFromPrekey(sessionId: String, prekey: [UInt8]) throws {
        try self.coreCrypto.proteusSessionFromPrekey(sessionId: sessionId, prekey: prekey)
    }

    /// Create a Proteus session from a handshake message
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - parameter envelope: CBOR-encoded Proteus message
    public func proteusSessionFromMessage(sessionId: String, envelope: [UInt8]) throws -> [UInt8]{
        return try self.coreCrypto.proteusSessionFromMessage(sessionId: sessionId, envelope: envelope)
    }

    /// Locally persists a session to the keystore
    ///
    /// - parameter sessionId: ID of the Proteus session
    public func proteusSessionSave(sessionId: String) throws {
        try self.coreCrypto.proteusSessionSave(sessionId: sessionId)
    }

    /// Deletes a session
    /// Note: this also deletes the persisted data within the keystore
    ///
    /// - parameter sessionId: ID of the Proteus session
    public func proteusSessionDelete(sessionId: String) throws {
        try self.coreCrypto.proteusSessionDelete(sessionId: sessionId)
    }

    /// Checks if a session exists
    ///
    /// - parameter sessionId: ID of the Proteus session
    public func proteusSessionExists(sessionId: String) throws -> Bool {
        try self.coreCrypto.proteusSessionExists(sessionId: sessionId)
    }

    /// Decrypt an incoming message for an existing Proteus session
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - parameter ciphertext: CBOR encoded, encrypted proteus message
    /// - returns: The decrypted payload contained within the message
    public func proteusDecrypt(sessionId: String, ciphertext: [UInt8]) throws -> [UInt8] {
        try self.coreCrypto.proteusDecrypt(sessionId: sessionId, ciphertext: ciphertext)
    }

    /// Encrypt a message for a given Proteus session
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - parameter plaintext: payload to encrypt
    /// - returns: The CBOR-serialized encrypted message
    public func proteusEncrypt(sessionId: String, plaintext: [UInt8]) throws -> [UInt8] {
        try self.coreCrypto.proteusEncrypt(sessionId: sessionId, plaintext: plaintext)
    }

    /// Batch encryption for proteus messages
    /// This is used to minimize FFI roundtrips when used in the context of a multi-client session (i.e. conversation)
    ///
    /// - parameter sessions: List of Proteus session IDs to encrypt the message for
    /// - parameter plaintext: payload to encrypt
    /// - returns: A map indexed by each session ID and the corresponding CBOR-serialized encrypted message for this session
    public func proteusEncryptBatched(sessions: [String], plaintext: [UInt8]) throws -> [String: [UInt8]] {
        try self.coreCrypto.proteusEncryptBatched(sessionId: sessions, plaintext: plaintext)
    }

    /// Creates a new prekey with the requested ID.
    ///
    /// - parameter prekeyId: ID of the PreKey to generate
    /// - returns: A CBOR-serialized version of the PreKeyBundle corresponding to the newly generated and stored PreKey
    public func proteusNewPrekey(prekeyId: UInt16) throws -> [UInt8] {
        try self.coreCrypto.proteusNewPrekey(prekeyId: prekeyId)
    }

    /// Creates a new prekey with an automatically incremented ID.
    ///
    /// - returns: A CBOR-serialized version of the PreKeyBundle corresponding to the newly generated and stored PreKey
    public func proteusNewPrekeyAuto() throws -> ProteusAutoPrekeyBundle {
        try self.coreCrypto.proteusNewPrekeyAuto().convertTo()
    }

    /// - returns: A CBOR-serialized verison of the PreKeyBundle associated to the last resort prekey ID
    public func proteusLastResortPrekey() throws -> [UInt8] {
        try self.coreCrypto.proteusLastResortPrekey()
    }

    /// - returns: The ID of the Proteus last resort PreKey
    public func proteusLastResortPrekeyId() throws -> UInt16 {
        try self.coreCrypto.proteusLastResortPrekeyId()
    }

    /// Proteus public key fingerprint
    /// It's basically the public key encoded as an hex string
    ///
    /// - returns: Hex-encoded public key string
    public func proteusFingerprint() throws -> String {
        try self.coreCrypto.proteusFingerprint()
    }

    /// Proteus session local fingerprint
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - returns: Hex-encoded public key string
    public func proteusFingerprintLocal(sessionId: String) throws -> String {
        try self.coreCrypto.proteusFingerprintLocal(sessionId: sessionId)
    }

    /// Proteus session remote fingerprint
    ///
    /// - parameter sessionId: ID of the Proteus session
    /// - returns: Hex-encoded public key string
    public func proteusFingerprintRemote(sessionId: String) throws -> String {
        try self.coreCrypto.proteusFingerprintRemote(sessionId: sessionId)
    }

    /// Hex-encoded fingerprint of the given prekey
    ///
    /// - parameter prekey: the prekey bundle to get the fingerprint from
    /// - returns: Hex-encoded public key string
    public func proteusFingerprintPrekeybundle(prekey: [UInt8]) throws -> String {
        try self.coreCrypto.proteusFingerprintPrekeybundle(prekey: prekey)
    }

    /// Imports all the data stored by Cryptobox into the CoreCrypto keystore
    ///
    /// - parameter path: Path to the folder where Cryptobox things are stored
    public func proteusCryptoboxMigrate(path: String) throws {
        try self.coreCrypto.proteusCryptoboxMigrate(path: path)
    }

    /// Creates an enrollment instance with private key material you can use in order to fetch
    /// a new x509 certificate from the acme server.
    ///
    /// - parameter ciphersuite: For generating signing key material. Only ``CoreCryptoSwift.CiphersuiteName.mls128Dhkemx25519Aes128gcmSha256Ed25519`` is supported currently
    /// - returns: The new ``CoreCryptoSwift.WireE2eIdentity`` object
    public func newAcmeEnrollment(ciphersuite: CoreCryptoSwift.CiphersuiteName = CoreCryptoSwift.CiphersuiteName.mls128Dhkemx25519Aes128gcmSha256Ed25519) throws -> CoreCryptoSwift.WireE2eIdentity {
        if ciphersuite != CoreCryptoSwift.CiphersuiteName.mls128Dhkemx25519Aes128gcmSha256Ed25519 {
            throw CoreCryptoSwift.E2eIdentityError.NotYetSupported(message: "This ACME ciphersuite isn't supported. Only `Ciphersuite.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519` is as of now")
        }

        return try self.coreCrypto.newAcmeEnrollment(ciphersuite: ciphersuite)
    }

    /// - returns: The CoreCrypto version
    public static func version() -> String {
        return CoreCryptoSwift.version()
    }
}
