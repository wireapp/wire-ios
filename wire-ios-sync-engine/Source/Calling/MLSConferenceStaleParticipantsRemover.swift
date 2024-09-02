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

import Combine
import Foundation
import WireDataModel
import WireUtilities

/// A class responsible for removing stale participants in a MLS conference.
///
/// Confluence use case:
/// https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/698908878/Use+case+remove+stale+participants+MLS

class MLSConferenceStaleParticipantsRemover: Subscriber {

    typealias Input = MLSConferenceParticipantsInfo
    typealias Failure = Never

    private let timerManager = TimerManager<MLSClientID>()
    private let logger = WireLogger.mls
    private let removalTimeout: TimeInterval
    private let mlsService: MLSServiceInterface
    private let syncContext: NSManagedObjectContext
    private var previousInput: MLSConferenceParticipantsInfo?
    private var subscription: Subscription?

    private static let defaultRemovalTimeout: TimeInterval = 180

    private typealias TimerError = TimerManager<MLSClientID>.TimerError

    // MARK: - Life cycle

    init(mlsService: MLSServiceInterface,
         syncContext: NSManagedObjectContext,
         removalTimeout: TimeInterval = defaultRemovalTimeout
    ) {
        self.mlsService = mlsService
        self.syncContext = syncContext
        self.removalTimeout = removalTimeout
    }

    deinit {
        stopSubscribing()
    }

    // MARK: - Subscriber implementation

    func stopSubscribing() {
        subscription?.cancel()
        subscription = nil
    }

    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }

    func receive(_ input: MLSConferenceParticipantsInfo) -> Subscribers.Demand {
        WaitingGroupTask(context: syncContext) { [self] in
            await process(input: input)
        }
        return .unlimited
    }

    func receive(completion: Subscribers.Completion<Never>) {
        // no op
    }

    // MARK: - Interface

    func cancelPendingRemovals() {
        timerManager.cancelAllTimers()
    }

    // MARK: - Participants change handling

    private func process(input: MLSConferenceParticipantsInfo) async {

        guard let subconversationMembers = await subconversationMembers(for: input.subconversationID) else {
            return
        }

        await syncContext.perform { [self] in
            let newAndChangedParticipants = newAndChangedParticipants(
                between: previousInput?.participants ?? [],
                and: input.participants
            )

            newAndChangedParticipants.excludingParticipant(withID: input.selfUserID).forEach {

                guard let clientID = MLSClientID(callParticipant: $0) else {
                    return
                }

                switch (subconversationMembers.contains(clientID), $0.state) {
                case (true, .connecting):
                    enqueueRemove(
                        client: clientID,
                        from: input.subconversationID,
                        after: removalTimeout
                    )
                case (false, _), (_, .connected):
                    cancelRemoval(for: clientID)
                default: break
                }
            }

            previousInput = input
        }
    }

    private func newAndChangedParticipants(between previous: [CallParticipant], and current: [CallParticipant]) -> [CallParticipant] {
        var newAndChanged = [CallParticipant]()

        // Object to uniquely identify and compare participant
        struct UniqueKey: Hashable {
            var clientId: String
            var userId: AVSIdentifier
        }

        let previousStates = Dictionary(uniqueKeysWithValues: previous.map { (UniqueKey(clientId: $0.clientId, userId: $0.userId), $0.state) })

        current.forEach { participant in
            let participantUniqueKey = UniqueKey(clientId: participant.clientId,
                                                 userId: participant.userId)
            if let previousState = previousStates[participantUniqueKey], previousState != participant.state {
                newAndChanged.append(participant)
            } else if previousStates[participantUniqueKey] == nil {
                newAndChanged.append(participant)
            }
        }

        return newAndChanged
    }

    // MARK: - Helpers

    private func subconversationMembers(for groupID: MLSGroupID) async -> [MLSClientID]? {
        do {
            return try await mlsService.subconversationMembers(for: groupID)
        } catch {
            logger.warn("failed to fetch subconversation members: \(String(describing: error))")
            return nil
        }
    }

    private func enqueueRemove(
        client clientID: MLSClientID,
        from groupID: MLSGroupID,
        after duration: TimeInterval
    ) {
        do {
            try timerManager.startTimer(
                for: clientID,
                duration: duration,
                completion: { [weak self] in
                    guard let self else { return }

                    WaitingGroupTask(context: syncContext) { [self] in
                        await self.remove(
                            client: clientID,
                            from: groupID
                        )
                    }
                }
            )

            logger.info("started timer for removal of stale participant (clientdID: \(clientID), groupID: \(groupID.safeForLoggingDescription))")
        } catch TimerError.timerAlreadyExists {
            // timer already exists, do nothing
        } catch {
            logger.warn("failed to start timer for removal of stale participant (clientdID: \(clientID), groupID: \(groupID.safeForLoggingDescription)). error: (\(error))")
        }
    }

    private func remove(
        client clientID: MLSClientID,
        from groupID: MLSGroupID
    ) async {
        do {
            let subconversationMembers = try await mlsService.subconversationMembers(for: groupID)

            guard subconversationMembers.contains(clientID) else {
                logger.info("didn't remove participant because they're not a part of the subconversation \(groupID.safeForLoggingDescription)")
                return
            }

            try await mlsService.removeMembersFromConversation(with: [clientID], for: groupID)
            logger.info("removed stale participant from subconversation (clientID: \(clientID), groupID: \(groupID.safeForLoggingDescription))")
        } catch {
            logger.error("failed to remove stale participant from subconversation: \(String(reflecting: error))")
        }
    }

    private func cancelRemoval(for clientID: MLSClientID) {
        do {
            try timerManager.cancelTimer(for: clientID)
            logger.info("canceled removal of participant (\(clientID))")
        } catch TimerError.timerNotFound {
            // no timer to cancel, do nothing
        } catch {
            logger.warn("failed to cancel removal of participant (\(clientID))")
        }
    }

}

private extension Array where Element == CallParticipant {

    func excludingParticipant(withID userID: AVSIdentifier) -> Self {
        filter {
            $0.userId != userID
        }
    }

}

private extension MLSClientID {
    init?(callParticipant: CallParticipant) {
        // Note: callParticipant user comes from uiMoc and init is called from syncContext
        guard let context = (callParticipant.user as? ZMUser)?.managedObjectContext else {
            assertionFailure("expecting ZMUser's context")
            return nil
        }
        let (remoteIdentifier, domain) = context.performAndWait {
            (callParticipant.user.remoteIdentifier, callParticipant.user.domain)
        }
        guard
            let userID = remoteIdentifier?.transportString(),
            let domain
        else {
            return nil
        }

        self.init(
            userID: userID,
            clientID: callParticipant.clientId,
            domain: domain
        )
    }
}
