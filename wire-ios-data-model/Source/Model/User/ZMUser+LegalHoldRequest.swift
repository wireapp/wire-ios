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
import WireCryptobox

private let log = ZMSLog(tag: "UserClient")

public typealias SelfUserLegalHoldable = EditableUserType & SelfLegalHoldSubject & UserType

// MARK: - SelfLegalHoldSubject

/// A protocol for objects that provide the legal hold status for the self user.

public protocol SelfLegalHoldSubject {
    /// The current legal hold status of the user.
    var legalHoldStatus: UserLegalHoldStatus { get }

    /// Whether the user needs to acknowledge the current legal hold status.
    var needsToAcknowledgeLegalHoldStatus: Bool { get }

    /// The legal hold client's fingerprint.
    var fingerprint: String? { get async }

    /// Call this method a pending legal hold request was cancelled
    func legalHoldRequestWasCancelled()

    /// Call this method when the user received a legal hold request.
    func userDidReceiveLegalHoldRequest(_ request: LegalHoldRequest)

    /// Call this method when the user accepts a legal hold request.
    func userDidAcceptLegalHoldRequest(_ request: LegalHoldRequest)

    /// Call this method when the user acknowledges their legal hold status.
    func acknowledgeLegalHoldStatus()
}

// MARK: - UserLegalHoldStatus

/// Describes the status of legal hold for the user.

@frozen
public enum UserLegalHoldStatus: Equatable {
    /// Legal hold is enabled for the user.
    case enabled

    /// A legal hold request is pending the user's approval.
    case pending(LegalHoldRequest)

    /// Legal hold is disabled for the user.
    case disabled
}

// MARK: - LegalHoldRequest

/// Describes a request to enable legal hold, created from the update event.

public struct LegalHoldRequest: Codable, Hashable {
    // MARK: Lifecycle

    // MARK: Initialization

    public init(target: UUID, requester: UUID, clientIdentifier: String, lastPrekey: Prekey) {
        self.target = target
        self.requester = requester
        self.client = Client(id: clientIdentifier)
        self.lastPrekey = lastPrekey
    }

    // MARK: Public

    /// Represents a prekey in the legal hold request.

    public struct Prekey: Codable, Hashable {
        // MARK: Lifecycle

        public init(id: Int, key: Data) {
            self.id = id
            self.key = key
        }

        // MARK: Public

        /// The ID of the key.
        public let id: Int

        /// The body of the key.
        public let key: Data
    }

    /// The last prekey for the legal hold client.
    public let lastPrekey: Prekey
    /// The user id of the user receiving the legal hold request
    public let target: UUID?
    /// The user id of the admin that issued the the legal hold request
    public let requester: UUID?

    /// The ID of the legal hold client.
    public var clientIdentifier: String {
        client.id
    }

    // MARK: Internal

    static func decode(from data: Data) -> LegalHoldRequest? {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        return try? decoder.decode(LegalHoldRequest.self, from: data)
    }

    func encode() -> Data? {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        return try? encoder.encode(self)
    }

    // MARK: Private

    /// Represent a client in the legal hold request.

    private struct Client: Codable, Hashable {
        /// The ID of the client
        let id: String
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case target = "id"
        case requester
        case client
        case lastPrekey = "last_prekey"
    }

    private let client: Client
}

extension ZMUserKeys {
    /// The key path to access the current legal hold request.
    static let legalHoldRequest = "legalHoldRequest"
}

// MARK: - ZMUser + SelfLegalHoldSubject

extension ZMUser: SelfLegalHoldSubject {
    // MARK: - Legal Hold Status

    /// The keys that affect the legal hold status for the user.
    static func keysAffectingLegalHoldStatus() -> Set<String> {
        [#keyPath(ZMUser.clients), ZMUserKeys.legalHoldRequest]
    }

    /// The current legal hold status for the user.
    public var legalHoldStatus: UserLegalHoldStatus {
        if clients.any(\.isLegalHoldDevice) {
            .enabled
        } else if let legalHoldRequest {
            .pending(legalHoldRequest)
        } else {
            .disabled
        }
    }

    // MARK: - Legal Hold Request

    @NSManaged private var primitiveLegalHoldRequest: Data?

    var legalHoldRequest: LegalHoldRequest? {
        get {
            willAccessValue(forKey: ZMUserKeys.legalHoldRequest)
            let value = primitiveLegalHoldRequest.flatMap(LegalHoldRequest.decode)
            didAccessValue(forKey: ZMUserKeys.legalHoldRequest)
            return value
        }
        set {
            willChangeValue(forKey: ZMUserKeys.legalHoldRequest)
            primitiveLegalHoldRequest = newValue.flatMap { $0.encode() }
            didChangeValue(forKey: ZMUserKeys.legalHoldRequest)
        }
    }

    /// Call this method a pending legal hold request was cancelled

    public func legalHoldRequestWasCancelled() {
        legalHoldRequest = nil
        needsToAcknowledgeLegalHoldStatus = false
    }

    /// Call this method when the user accepted the legal hold request.
    /// - parameter request: The request that the user received.

    public func userDidAcceptLegalHoldRequest(_ request: LegalHoldRequest) {
        guard
            // The request must match the current request to avoid nil-ing it out by mistake.
            request == legalHoldRequest,
            isSelfUser,
            let context = managedObjectContext
        else {
            return
        }

        legalHoldRequest = nil

        guard let legalHoldClient = clients.filter(\.isLegalHoldDevice).first else {
            return
        }

        let predicateFactory = ConversationPredicateFactory(selfTeam: team)
        let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        fetchRequest.predicate = predicateFactory.predicateForConversationsIncludingArchived()

        for conversation in context.fetchOrAssert(request: fetchRequest) {
            // Add the legal hold enabled system message locally.
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(
                clients: [legalHoldClient],
                causedBy: [self]
            )
        }
    }

    /// Adds a legal hold client for the user from the specified legal hold request.
    /// - parameter request: The legal hold request that contains the details of the client.
    /// - returns: The created client, if the state is valid.

    public func addLegalHoldClient(from request: LegalHoldRequest) async -> UserClient? {
        guard
            let context = managedObjectContext,
            let selfClient = await context.perform({ self.selfClient() }),
            let legalHoldClient = await context.perform({ self.insertLegalHoldClient(from: request, in: context) })
        else { return nil }

        guard await selfClient.establishSessionWithClient(
            legalHoldClient,
            usingPreKey: request.lastPrekey.key.base64String()
        ) else {
            log.error("Could not establish session with new legal hold device.")
            await context.perform { context.delete(legalHoldClient) }
            return nil
        }

        return legalHoldClient
    }

    private func insertLegalHoldClient(
        from request: LegalHoldRequest,
        in context: NSManagedObjectContext
    ) -> UserClient? {
        let legalHoldClient = UserClient.insertNewObject(in: context)
        legalHoldClient.type = .legalHold
        legalHoldClient.deviceClass = .legalHold
        legalHoldClient.remoteIdentifier = request.clientIdentifier
        legalHoldClient.user = self

        return legalHoldClient
    }

    /// Call this method when the user received a legal hold request from their admin.
    /// - parameter request: The request that the user received.

    public func userDidReceiveLegalHoldRequest(_ request: LegalHoldRequest) {
        guard request.target == nil || request.target == remoteIdentifier else {
            // Do not handle requests if the user ID doesn't match the self user ID
            return
        }

        legalHoldRequest = request
        needsToAcknowledgeLegalHoldStatus = true
    }

    // MARK: - Status Acknowledgement

    /// Whether the user needs to be notified about a legal hold status change.
    @NSManaged public internal(set) var needsToAcknowledgeLegalHoldStatus: Bool

    /// Call this method when the user acknowledged the last legal hold status.

    public func acknowledgeLegalHoldStatus() {
        needsToAcknowledgeLegalHoldStatus = false
    }

    // MARK: - Fingerprint

    public var fingerprint: String? {
        get async {
            guard let (syncContext, prekey) = await managedObjectContext?.perform({
                (self.managedObjectContext?.zm_sync, self.legalHoldRequest?.lastPrekey)
            }), let syncContext, let prekey else { return nil }

            let proteusProvider = await syncContext.perform { syncContext.proteusProvider }
            return await proteusProvider.performAsync { proteusService in
                await fetchFingerprint(for: prekey, through: proteusService)
            } withKeyStore: { keyStore in
                fetchFingerprint(for: prekey, through: keyStore)
            }
        }
    }

    private func fetchFingerprint(
        for prekey: LegalHoldRequest.Prekey,
        through proteusService: ProteusServiceInterface
    ) async -> String? {
        do {
            return try await proteusService.fingerprint(fromPrekey: prekey.key.base64EncodedString())
        } catch {
            log.error("Could not fetch fingerprint for \(self)")
            return nil
        }
    }

    private func fetchFingerprint(
        for prekey: LegalHoldRequest.Prekey,
        through keystore: UserClientKeysStore
    ) -> String? {
        guard let fingerprintData = EncryptionSessionsDirectory.fingerprint(fromPrekey: prekey.key) else { return nil }
        return String(decoding: fingerprintData, as: UTF8.self)
    }
}
