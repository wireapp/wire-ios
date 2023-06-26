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

extension WireCallCenterV3 {

    func updateMLSConferenceIfNeeded(
        conversationID: AVSIdentifier,
        callState: CallState
    ) {
        switch callState {
        case .incoming, .terminating:
            leaveStaleConferenceIfNeeded(conversationID: conversationID)

        default:
            break
        }
    }

    func updateMLSConferenceIfNeededForMissedCall(conversationID: AVSIdentifier) {
        leaveStaleConferenceIfNeeded(conversationID: conversationID)
    }

    private func leaveStaleConferenceIfNeeded(conversationID: AVSIdentifier) {
        guard
            let viewContext = uiMOC,
            let syncContext = viewContext.zm_sync,
            let domain = conversationID.domain ?? BackendInfo.domain,
            let conversation = ZMConversation.fetch(
                with: conversationID.identifier,
                domain: domain,
                in: viewContext
            ),
            conversation.messageProtocol == .mls,
            let parentGroupID = conversation.mlsGroupID,
            let selfClient = ZMUser.selfUser(in: viewContext).selfClient(),
            let selfClientID = MLSClientID(userClient: selfClient)
        else {
            return
        }

        syncContext.perform {
            guard let mlsService = syncContext.mlsService else {
                return
            }

            let parentQualifiedID = QualifiedID(
                uuid: conversationID.identifier,
                domain: domain
            )

            Task {
                do {
                    try await mlsService.leaveSubconversationIfNeeded(
                        parentQualifiedID: parentQualifiedID,
                        parentGroupID: parentGroupID,
                        subconversationType: .conference,
                        selfClientID: selfClientID
                    )
                } catch {
                    WireLogger.calling.warn("failed to leave stale conference if needed: \(String(describing: error))")
                }
            }
        }
    }

}
