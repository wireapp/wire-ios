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

import Foundation
import GenericMessageProtocol
import WireLogging

/// Sends a session reset message to a client whose `needsToNotifyOtherUserAboutSessionReset` flag is set.
///
/// The flag is set when the user resets a session manually, and automatically when the Proteus session with a client
/// is broken (see `ProteusSessionRepairScheduler`). Whenever possible, the session is rebuilt over Proteus:
///
/// 1. delete the local session with the client,
/// 2. establish a new session from the client's prekey,
/// 3. send the session reset message to that client only, in a Proteus conversation both users are part of.
///
/// The client then receives a prekey message, switches to the new session, and its messages decrypt again.
/// Sending through the 1:1 conversation instead doesn't work when it uses MLS, so that is only the fallback when
/// no Proteus conversation is shared.
public class ResetSessionRequestStrategy: NSObject, ZMContextChangeTrackerSource {

    fileprivate let keyPathSync: KeyPathObjectSync<ResetSessionRequestStrategy>
    fileprivate let messageSender: MessageSenderInterface
    fileprivate let sessionEstablisher: SessionEstablisherInterface?
    fileprivate let apiVersion: APIVersion?
    fileprivate let managedObjectContext: NSManagedObjectContext

    public init(
        managedObjectContext: NSManagedObjectContext,
        messageSender: MessageSenderInterface,
        sessionEstablisher: SessionEstablisherInterface? = nil,
        apiVersion: APIVersion? = nil
    ) {

        self.managedObjectContext = managedObjectContext
        self.keyPathSync = KeyPathObjectSync(
            entityName: UserClient.entityName(),
            \.needsToNotifyOtherUserAboutSessionReset
        )
        self.messageSender = messageSender
        self.sessionEstablisher = sessionEstablisher
        self.apiVersion = apiVersion

        super.init()

        keyPathSync.transcoder = self
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [keyPathSync]
    }

}

extension ResetSessionRequestStrategy: KeyPathObjectSyncTranscoder {

    typealias T = UserClient

    func synchronize(_ userClient: UserClient, completion: @escaping () -> Void) {
        guard let user = userClient.user else {
            return
        }

        if
            let sessionEstablisher,
            let apiVersion,
            let qualifiedClientID = userClient.qualifiedClientID,
            let conversation = sharedProteusConversation(with: user) {
            let message = GenericMessageEntity(
                message: GenericMessage(clientAction: .resetSession),
                context: managedObjectContext,
                conversation: conversation,
                targetRecipients: .clients([user: [userClient]]),
                completionHandler: nil
            )

            send(resolving: userClient, completion: completion) { [self] in
                // Clients without a session are silently dropped when targeting specific clients, so the new session
                // must exist before sending.
                try await userClient.deleteSession()
                try await sessionEstablisher.establishSession(with: [qualifiedClientID], apiVersion: apiVersion)
                try await messageSender.sendMessage(message: message)
            }
        } else if let conversation = user.oneToOneConversation {
            let message = GenericMessageEntity(
                message: GenericMessage(clientAction: .resetSession),
                context: managedObjectContext,
                conversation: conversation,
                completionHandler: nil
            )

            send(resolving: userClient, completion: completion) { [self] in
                try await messageSender.sendMessage(message: message)
            }
        }
    }

    func cancel(_ object: UserClient) {}

    private func send(
        resolving userClient: UserClient,
        completion: @escaping () -> Void,
        operation: @escaping () async throws -> Void
    ) {
        WaitingGroupTask(context: managedObjectContext) { [self] in
            do {
                try await operation()
                await managedObjectContext.perform {
                    userClient.resolveDecryptionFailedSystemMessages()
                }
            } catch {
                WireLogger.messaging.error("Failed to send reset session message: \(error)")
            }

            await managedObjectContext.perform {
                completion()
                // saving since the `needsToNotifyOtherUserAboutSessionReset` are reset in the completion block
                self.managedObjectContext.enqueueDelayedSave()
            }
        }
    }

    /// A conversation using Proteus that both the self user and `user` are part of, preferring a 1:1 conversation,
    /// then the most recently active group.
    private func sharedProteusConversation(with user: ZMUser) -> ZMConversation? {
        if user.isSelfUser {
            let selfConversation = ZMConversation.selfConversation(in: managedObjectContext)
            return selfConversation.messageProtocol == .proteus ? selfConversation : nil
        }

        let candidates = user.activeConversations.filter { conversation in
            [.proteus, .mixed].contains(conversation.messageProtocol) &&
                conversation.isSelfAnActiveMember &&
                [.oneOnOne, .group].contains(conversation.conversationType)
        }

        return candidates.max { lhs, rhs in
            let lhsIsOneOnOne = lhs.conversationType == .oneOnOne
            let rhsIsOneOnOne = rhs.conversationType == .oneOnOne
            if lhsIsOneOnOne != rhsIsOneOnOne {
                return !lhsIsOneOnOne
            }
            return (lhs.lastModifiedDate ?? .distantPast) < (rhs.lastModifiedDate ?? .distantPast)
        }
    }

}
