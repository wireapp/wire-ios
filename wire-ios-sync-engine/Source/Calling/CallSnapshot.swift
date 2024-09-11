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

/// The snapshot of the state of a call.

struct CallSnapshot {
    var qualifiedID: QualifiedID?
    var groupIDs: (parent: MLSGroupID, subconversation: MLSGroupID)?

    let callParticipants: CallParticipantsSnapshot
    let callState: CallState
    let callStarter: AVSIdentifier
    let isVideo: Bool
    let isGroup: Bool
    let isConstantBitRate: Bool
    let videoState: VideoState
    let networkQuality: NetworkQuality
    let conversationType: AVSConversationType
    let degradedUser: ZMUser?
    let activeSpeakers: [AVSActiveSpeakersChange.ActiveSpeaker]
    let videoGridPresentationMode: VideoGridPresentationMode
    var conversationObserverToken: NSObjectProtocol?
    var mlsConferenceStaleParticipantsRemover: MLSConferenceStaleParticipantsRemover?
    var updateConferenceInfoTask: Task<Void, Never>?

    var isDegradedCall: Bool {
        degradedUser != nil
    }

    /// Updates the snapshot with the new state of the call.
    /// - parameter callState: The new state of the call computed from AVS.

    func update(with callState: CallState) -> CallSnapshot {
        CallSnapshot(
            qualifiedID: qualifiedID,
            groupIDs: groupIDs,
            callParticipants: callParticipants,
            callState: callState,
            callStarter: callStarter,
            isVideo: isVideo,
            isGroup: isGroup,
            isConstantBitRate: isConstantBitRate,
            videoState: videoState,
            networkQuality: networkQuality,
            conversationType: conversationType,
            degradedUser: degradedUser,
            activeSpeakers: activeSpeakers,
            videoGridPresentationMode: videoGridPresentationMode,
            conversationObserverToken: conversationObserverToken,
            mlsConferenceStaleParticipantsRemover: mlsConferenceStaleParticipantsRemover,
            updateConferenceInfoTask: updateConferenceInfoTask
        )
    }

    /// Updates the snapshot with the CBR state.
    /// - parameter enabled: Whether constant bitrate was enabled.

    func updateConstantBitrate(_ enabled: Bool) -> CallSnapshot {
        CallSnapshot(
            qualifiedID: qualifiedID,
            groupIDs: groupIDs,
            callParticipants: callParticipants,
            callState: callState,
            callStarter: callStarter,
            isVideo: isVideo,
            isGroup: isGroup,
            isConstantBitRate: enabled,
            videoState: videoState,
            networkQuality: networkQuality,
            conversationType: conversationType,
            degradedUser: degradedUser,
            activeSpeakers: activeSpeakers,
            videoGridPresentationMode: videoGridPresentationMode,
            conversationObserverToken: conversationObserverToken,
            mlsConferenceStaleParticipantsRemover: mlsConferenceStaleParticipantsRemover,
            updateConferenceInfoTask: updateConferenceInfoTask
        )
    }

    /// Updates the snapshot with the new video state.
    /// - parameter videoState: The new video state.

    func updateVideoState(_ videoState: VideoState) -> CallSnapshot {
        CallSnapshot(
            qualifiedID: qualifiedID,
            groupIDs: groupIDs,
            callParticipants: callParticipants,
            callState: callState,
            callStarter: callStarter,
            isVideo: isVideo,
            isGroup: isGroup,
            isConstantBitRate: isConstantBitRate,
            videoState: videoState,
            networkQuality: networkQuality,
            conversationType: conversationType,
            degradedUser: degradedUser,
            activeSpeakers: activeSpeakers,
            videoGridPresentationMode: videoGridPresentationMode,
            conversationObserverToken: conversationObserverToken,
            mlsConferenceStaleParticipantsRemover: mlsConferenceStaleParticipantsRemover,
            updateConferenceInfoTask: updateConferenceInfoTask
        )
    }

    /// Updates the snapshot with the new network condition.
    /// - parameter networkCondition: The new network condition.

    func updateNetworkQuality(_ networkQuality: NetworkQuality) -> CallSnapshot {
        CallSnapshot(
            qualifiedID: qualifiedID,
            groupIDs: groupIDs,
            callParticipants: callParticipants,
            callState: callState,
            callStarter: callStarter,
            isVideo: isVideo,
            isGroup: isGroup,
            isConstantBitRate: isConstantBitRate,
            videoState: videoState,
            networkQuality: networkQuality,
            conversationType: conversationType,
            degradedUser: degradedUser,
            activeSpeakers: activeSpeakers,
            videoGridPresentationMode: videoGridPresentationMode,
            conversationObserverToken: conversationObserverToken,
            mlsConferenceStaleParticipantsRemover: mlsConferenceStaleParticipantsRemover,
            updateConferenceInfoTask: updateConferenceInfoTask
        )
    }

    /// Updates the snapshot with the new degraded user.
    /// 
    /// A user degrades the call if they were previously trusted by the self
    /// client and then joined the call with an unverified device.
    /// 
    /// - parameter degradedUser: The user who degraded the call.

    func updateDegradedUser(_ degradedUser: ZMUser) -> CallSnapshot {
        CallSnapshot(
            qualifiedID: qualifiedID,
            groupIDs: groupIDs,
            callParticipants: callParticipants,
            callState: callState,
            callStarter: callStarter,
            isVideo: isVideo,
            isGroup: isGroup,
            isConstantBitRate: isConstantBitRate,
            videoState: videoState,
            networkQuality: networkQuality,
            conversationType: conversationType,
            degradedUser: degradedUser,
            activeSpeakers: activeSpeakers,
            videoGridPresentationMode: videoGridPresentationMode,
            conversationObserverToken: conversationObserverToken,
            mlsConferenceStaleParticipantsRemover: mlsConferenceStaleParticipantsRemover,
            updateConferenceInfoTask: updateConferenceInfoTask
        )
    }

    /// Updates the snapshot with the new audio levels of the call.
    /// - parameter activeSpeakers: The new active speakers of the call computed from AVS.

    func updateActiveSpeakers(_ activeSpeakers: [AVSActiveSpeakersChange.ActiveSpeaker]) -> CallSnapshot {
        CallSnapshot(
            qualifiedID: qualifiedID,
            groupIDs: groupIDs,
            callParticipants: callParticipants,
            callState: callState,
            callStarter: callStarter,
            isVideo: isVideo,
            isGroup: isGroup,
            isConstantBitRate: isConstantBitRate,
            videoState: videoState,
            networkQuality: networkQuality,
            conversationType: conversationType,
            degradedUser: degradedUser,
            activeSpeakers: activeSpeakers,
            videoGridPresentationMode: videoGridPresentationMode,
            conversationObserverToken: conversationObserverToken,
            mlsConferenceStaleParticipantsRemover: mlsConferenceStaleParticipantsRemover,
            updateConferenceInfoTask: updateConferenceInfoTask
        )
    }

    /// Updates the snapshot with the new presentation mode of the video grid.
    /// - parameter presentationMode: The new mode of presentation in video grid

    func updateVideoGridPresentationMode(_ presentationMode: VideoGridPresentationMode) -> CallSnapshot {
        CallSnapshot(
            qualifiedID: qualifiedID,
            groupIDs: groupIDs,
            callParticipants: callParticipants,
            callState: callState,
            callStarter: callStarter,
            isVideo: isVideo,
            isGroup: isGroup,
            isConstantBitRate: isConstantBitRate,
            videoState: videoState,
            networkQuality: networkQuality,
            conversationType: conversationType,
            degradedUser: degradedUser,
            activeSpeakers: activeSpeakers,
            videoGridPresentationMode: presentationMode,
            conversationObserverToken: conversationObserverToken,
            mlsConferenceStaleParticipantsRemover: mlsConferenceStaleParticipantsRemover,
            updateConferenceInfoTask: updateConferenceInfoTask
        )
    }
}
