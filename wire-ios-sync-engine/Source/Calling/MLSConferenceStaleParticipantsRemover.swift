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
import Combine
import WireUtilities
import WireDataModel

class MLSConferenceStaleParticipantsRemover: Subscriber {

    typealias Input = MLSConferenceParticipantsInfo
    typealias Failure = Never

    private let timerManager = TimerManager<MLSClientID>()
    private let logger = WireLogger.mls
    private let removalTimeout: TimeInterval
    private let mlsService: MLSServiceInterface
    private let syncContext: NSManagedObjectContext
    private var previousInput: MLSConferenceParticipantsInfo?

    private static let defaultRemovalTimeout: TimeInterval = 190

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

    // MARK: - Subscriber implementation

    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    func receive(_ input: MLSConferenceParticipantsInfo) -> Subscribers.Demand {
        syncContext.perform {
            self.process(input: input)
        }
        return .unlimited
    }

    func receive(completion: Subscribers.Completion<Never>) {
        // no op
    }

    // MARK: - Interface

    func cancelPendingRemovals() {
        syncContext.perform {
            self.timerManager.cancelAllTimers()
        }
    }

    // MARK: - Participants change handling

    private func process(input: MLSConferenceParticipantsInfo) {

        guard let subconversationMembers = subconversationMembers(for: input.subconversationID) else {
            return
        }

        let newAndChangedParticipants = newAndChangedParticipants(
            between: previousInput?.participants ?? [],
            and: input.participants
        )

        newAndChangedParticipants.excludingSelf(in: syncContext).forEach {

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

    private func newAndChangedParticipants(between previous: [CallParticipant], and current: [CallParticipant]) -> [CallParticipant] {
        var newAndChanged = [CallParticipant]()

        let previousStates = Dictionary(uniqueKeysWithValues: previous.map { ($0.userId, $0.state) })

        current.forEach { participant in
            if let previousState = previousStates[participant.userId], previousState != participant.state {
                newAndChanged.append(participant)
            } else if previousStates[participant.userId] == nil {
                newAndChanged.append(participant)
            }
        }

        return newAndChanged
    }

    // MARK: - Helpers

    private func subconversationMembers(for groupID: MLSGroupID) -> [MLSClientID]? {
        do {
            return try mlsService.subconversationMembers(for: groupID)
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
                    guard let self = self else { return }

                    self.remove(
                        client: clientID,
                        from: groupID
                    )
                }
            )

            logger.info("started timer for removal of stale participant (clientdID: \(clientID), groupID: \(groupID))")
        } catch TimerError.timerAlreadyExists {
            // timer already exists, do nothing
        } catch {
            logger.warn("failed to start timer for removal of stale participant (clientdID: \(clientID), groupID: \(groupID)). error: (\(error))")
        }
    }

    private func remove(
        client clientID: MLSClientID,
        from groupID: MLSGroupID
    ) {
        syncContext.perform { [weak self] in
            guard let `self` = self else { return }

            Task {
                do {
                    let subconversationMembers = try self.mlsService.subconversationMembers(for: groupID)

                    guard subconversationMembers.contains(clientID) else {
                        return
                    }

                    try await self.mlsService.removeMembersFromConversation(with: [clientID], for: groupID)
                    self.logger.info("removed stale participant from subconversation (clientID: \(clientID), groupID: \(groupID))")
                } catch {
                    self.logger.error("failed to remove stale participant from subconversation: \(String(describing: error))")
                }
            }
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

    func excludingSelf(in context: NSManagedObjectContext) -> Self {
        var selfUserID: AVSIdentifier!

        context.performAndWait {
            let selfUser = ZMUser.selfUser(in: context)
            selfUserID = selfUser.avsIdentifier
        }

        return self.filter {
            $0.userId != selfUserID
        }
    }

}

private extension MLSClientID {
    init?(callParticipant: CallParticipant) {
        guard
            let userID = callParticipant.user.remoteIdentifier?.transportString(),
            let domain = callParticipant.user.domain
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
