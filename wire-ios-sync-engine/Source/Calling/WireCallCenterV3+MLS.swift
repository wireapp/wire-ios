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

struct ConferenceParticipantsInfo {
    let participants: [CallParticipant]
    let selfUserID: AVSIdentifier
}

struct MLSConferenceParticipantsInfo {
    let participants: [CallParticipant]
    let selfUserID: AVSIdentifier
    let subconversationID: MLSGroupID
}

extension WireCallCenterV3 {

    func onMLSConferenceParticipantsChanged(
        subconversationID: MLSGroupID
    ) -> AnyPublisher<MLSConferenceParticipantsInfo, Never> {
        onParticipantsChanged().compactMap {
            MLSConferenceParticipantsInfo(
                participants: $0.participants,
                selfUserID: $0.selfUserID,
                subconversationID: subconversationID
            )
        }.eraseToAnyPublisher()
    }

    func updateMLSConferenceIfNeeded(
        conversationID: AVSIdentifier,
        callState: CallState,
        callSnapshot: CallSnapshot?
    ) {
        switch callState {

        case .terminating:
            cancelPendingStaleParticipantsRemovals(callSnapshot: callSnapshot)
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

    func cancelPendingStaleParticipantsRemovals(
        callSnapshot: CallSnapshot?
    ) {
        callSnapshot?.mlsConferenceStaleParticipantsRemover?.cancelPendingRemovals()
    }

    // Leaves the possibles subconversation for the mls conference.

    private func leaveStaleConferenceIfNeeded(conversationID: AVSIdentifier) {
        guard
            let viewContext = uiMOC,
            let conversation = ZMConversation.fetch(
                with: conversationID.identifier,
                domain: conversationID.domain,
                in: viewContext
            ),
            conversation.conversationType == .group
        else {
            return
        }

        guard
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
                assertionFailure("mlsService is nil")
                return
            }

            Task {
                do {
                    try await mlsService.leaveSubconversation(
                        parentQualifiedID: parentQualifiedID,
                        parentGroupID: parentGroupID,
                        subconversationType: .conference
                    )
                } catch {
                    WireLogger.calling.error("failed to leave subconversation: \(String(reflecting: error))")
                }
            }
        }
    }

    func deleteSubconversation(conversationID: AVSIdentifier) {
        guard
            let viewContext = uiMOC,
            let syncContext = viewContext.zm_sync,
            let parentIDs = mlsParentIDS(for: conversationID)
        else {
            return
        }

        syncContext.perform {
            guard let mlsService = syncContext.mlsService else {
                WireLogger.calling.error("failed to delete subconversation: mlsService is missing")
                assertionFailure("mlsService is nil")
                return
            }

            Task {
                do {
                    try await mlsService.deleteSubgroup(parentQualifiedID: parentIDs.qualifiedID)
                } catch {
                    WireLogger.calling.error("failed to delete subconversation: \(String(reflecting: error))")
                }
            }
        }
    }

}

extension CallParticipantState {

    var isConnected: Bool {
        switch self {
        case .connected:
            return true
        default:
            return false
        }
    }

}
