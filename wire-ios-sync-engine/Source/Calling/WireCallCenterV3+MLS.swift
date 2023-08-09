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
import WireDataModel

struct MLSConferenceParticipantsInfo {
    let participants: [CallParticipant]
    let conversation: ZMConversation
    let subconversationID: MLSGroupID
}

extension WireCallCenterV3 {

    func onMLSConferenceParticipantsChanged(
        conversation: ZMConversation,
        subconversationID: MLSGroupID
    ) -> AnyPublisher<MLSConferenceParticipantsInfo, Never> {
        onParticipantsChanged().compactMap {
            MLSConferenceParticipantsInfo(
                participants: $0,
                conversation: conversation,
                subconversationID: subconversationID
            )
        }.eraseToAnyPublisher()
    }

    func updateMLSConferenceIfNeeded(
        conversationID: AVSIdentifier,
        callState: CallState
    ) {
        switch callState {

        case .terminating:
            removeStaleParticipantsIfNeeded(conversationID: conversationID)
            leaveStaleConferenceIfNeeded(conversationID: conversationID)

        case .incoming:
            leaveStaleConferenceIfNeeded(conversationID: conversationID)

        default:
            break
        }
    }

    func updateMLSConferenceIfNeededForMissedCall(conversationID: AVSIdentifier) {
        leaveStaleConferenceIfNeeded(conversationID: conversationID)
    }

    func removeStaleParticipantsIfNeeded(conversationID: AVSIdentifier) {
        guard
            let viewContext = uiMOC,
            let callSnaphot = callSnapshots[conversationID],
            let staleParticipantsRemover = callSnaphot.mlsConferenceStaleParticipantsRemover
        else {
            return
        }

        let selfUser = ZMUser.selfUser(in: viewContext)
        let participantsExcludingSelf = callSnaphot.callParticipants.participants.filter {
            $0.userId != selfUser.avsIdentifier
        }

        guard participantsExcludingSelf.isEmpty else {
            return
        }

        staleParticipantsRemover.performPendingRemovals()
    }

    func mlsParentIDS(for callID: AVSIdentifier) -> (qualifiedID: QualifiedID, groupID: MLSGroupID)? {
        guard
            let context = uiMOC,
            let domain = callID.domain ?? BackendInfo.domain,
            let conversation = ZMConversation.fetch(
                with: callID.identifier,
                domain: domain,
                in: context
            ),
            conversation.messageProtocol == .mls,
            let qualifiedID = conversation.qualifiedID,
            let groupID = conversation.mlsGroupID
        else {
            return nil
        }

        return (qualifiedID, groupID)
    }

    // Leaves the possibles subconversation for the mls conference.

    private func leaveStaleConferenceIfNeeded(conversationID: AVSIdentifier) {
        guard
            let viewContext = uiMOC,
            let syncContext = viewContext.zm_sync,
            let selfClient = ZMUser.selfUser(in: viewContext).selfClient(),
            let selfClientID = MLSClientID(userClient: selfClient),
            let parentIDs = mlsParentIDS(for: conversationID)
        else {
            return
        }

        syncContext.perform {
            guard let mlsService = syncContext.mlsService else {
                return
            }

            Task {
                do {
                    try await mlsService.leaveSubconversationIfNeeded(
                        parentQualifiedID: parentIDs.qualifiedID,
                        parentGroupID: parentIDs.groupID,
                        subconversationType: .conference,
                        selfClientID: selfClientID
                    )
                } catch {
                    WireLogger.calling.warn("failed to leave stale conference if needed: \(String(describing: error))")
                }
            }
        }
    }

    // Leaves the subconversation for the mls conference.

    func leaveSubconversation(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID
    ) {
        guard
            let context = uiMOC,
            let syncContext = context.zm_sync
        else {
            return
        }

        syncContext.perform {
            guard let mlsService = syncContext.mlsService else {
                WireLogger.calling.error("failed to leave subconversation: mlsService is missing")
                return
            }

            Task {
                try await mlsService.leaveSubconversation(
                    parentQualifiedID: parentQualifiedID,
                    parentGroupID: parentGroupID,
                    subconversationType: .conference
                )
            }
        }
    }

}
