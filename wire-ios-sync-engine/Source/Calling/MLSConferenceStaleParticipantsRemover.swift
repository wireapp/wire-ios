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
    private let context: NSManagedObjectContext

    // MARK: - Life cycle

    init(mlsService: MLSServiceInterface, context: NSManagedObjectContext, removalTimeout: TimeInterval = 190) {
        self.mlsService = mlsService
        self.context = context
        self.removalTimeout = removalTimeout
    }

    // MARK: - Subscriber implementation

    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    func receive(_ input: MLSConferenceParticipantsInfo) -> Subscribers.Demand {
        process(input: input)
        return .unlimited
    }

    func receive(completion: Subscribers.Completion<Never>) {
        // no op
    }

    // MARK: - Participants change handling

    private func process(input: MLSConferenceParticipantsInfo) {

        guard let subconversationMembers = subconversationMembers(for: input.subconversationID) else {
            return
        }

        input.participants.forEach {

            guard let clientID = MLSClientID(callParticipant: $0) else {
                return
            }

            switch (subconversationMembers.contains(clientID), $0.state) {
            case (true, .connecting):
                remove(
                    client: clientID,
                    from: input.subconversationID,
                    after: removalTimeout
                )
            case (false, _), (_, .connected):
                cancelRemoval(for: clientID)
            default: break
            }
        }
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

    private func remove(
        client clientID: MLSClientID,
        from groupID: MLSGroupID,
        after duration: TimeInterval
    ) {
        logger.info("starting timer for removal of stale participant (clientdID: \(clientID), groupID: \(groupID))")

        timerManager.startTimer(
            for: clientID,
            duration: duration,
            completion: { [weak self] in
                self?.remove(
                    client: clientID,
                    from: groupID
                )
            }
        )
    }

    private func remove(
        client clientID: MLSClientID,
        from groupID: MLSGroupID
    ) {
        context.perform { [weak self] in
            guard let `self` = self else { return }

            Task {
                do {
                    try await self.mlsService.removeMembersFromConversation(with: [clientID], for: groupID)
                    self.logger.info("removed stale participant from subconversation (clientID: \(clientID), groupID: \(groupID))")
                } catch {
                    self.logger.error("failed to remove stale participant from subconversation: \(String(describing: error))")
                }
            }
        }
    }

    private func cancelRemoval(for clientID: MLSClientID) {
        let canceled = timerManager.cancelTimer(for: clientID)

        if canceled {
            logger.info("canceled removal of participant (\(clientID))")
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
