//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import avs
import Foundation
import WireLogging

// MARK: Conversation Changes

extension WireCallCenterV3: ZMConversationObserver {

    public func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        handleSecurityLevelChange(changeInfo)
        handleActiveParticipantsChange(changeInfo)
        informMLSMigrationFinalizedIfNeeded(changeInfo)
        endCallIfNeeded(changeInfo)
    }

    private func handleSecurityLevelChange(_ changeInfo: ConversationChangeInfo) {
        guard
            changeInfo.securityLevelChanged || changeInfo.mlsVerificationStatusChanged,
            let conversationId = changeInfo.conversation.avsIdentifier,
            let previousSnapshot = callSnapshots[conversationId]
        else {
            return
        }

        if changeInfo.conversation.isDegraded, isActive(conversationId: conversationId) {
            // If an active call degrades we end it immediately
            return closeCall(conversationId: conversationId, reason: .securityDegraded)
        }

        let updatedCallState = previousSnapshot.callState
            .update(isConversationDegraded: changeInfo.conversation.isDegraded)

        if updatedCallState != previousSnapshot.callState {
            callSnapshots[conversationId] = previousSnapshot.update(with: updatedCallState)

            if let context = uiMOC, let callerId = initiatorForCall(conversationId: conversationId) {
                let notification = WireCallCenterCallStateNotification(
                    context: context,
                    callState: updatedCallState,
                    conversationId: conversationId,
                    callerId: callerId,
                    messageTime: Date(),
                    previousCallState: previousSnapshot.callState
                )
                notification.post(in: context.notificationContext)
            }
        }
    }

    private func handleActiveParticipantsChange(_ changeInfo: ConversationChangeInfo) {
        guard
            changeInfo.activeParticipantsChanged || changeInfo.participantsChanged,
            let conversationId = changeInfo.conversation.avsIdentifier,
            let completion = clientsRequestCompletionsByConversationId[conversationId]
        else {
            return
        }

        handleClientsRequest(conversationId: conversationId, completion: completion)
    }

    private func informMLSMigrationFinalizedIfNeeded(_ changeInfo: ConversationChangeInfo) {
        let conversation = changeInfo.conversation

        // We arrive here after observing a change in the conversation.
        // If the change info indicates that the message protocol changed,
        // Then we verify that it changed to mls.
        //
        // Note: it may happen that the message protocol key is marked as updated while its value didn't actually
        // change.
        // We therefore double check that the protocol saved in the callSnapshot upon call creation was not mls.

        guard
            let avsIdentifier = conversation.avsIdentifier,
            let snapshot = callSnapshots[avsIdentifier],
            let context = conversation.managedObjectContext,
            changeInfo.messageProtocolChanged,
            conversation.messageProtocol == .mls,
            snapshot.messageProtocol != .mls,
            !isMLSConferenceCall(conversationId: avsIdentifier)
        else {
            return
        }

        conversation.appendMLSMigrationOngoingCallSystemMessage(
            sender: ZMUser.selfUser(in: context),
            at: .now
        )
    }

    private func endCallIfNeeded(_ changeInfo: ConversationChangeInfo) {
        guard let conversationId = changeInfo.conversation.avsIdentifier else { return }

        if changeInfo.isDeletedChanged, changeInfo.conversation.isDeletedRemotely {
            Self.logger.info("closing call because conversation was deleted")
            closeCall(conversationId: conversationId)

        } else if !changeInfo.conversation.isSelfAnActiveMember {
            Self.logger.info("closing call because self user is not an active member")
            closeCall(conversationId: conversationId)
        }
    }

}

// MARK: - AVS Callbacks

extension WireCallCenterV3 {

    private func handleEvent(_ description: String, _ handlerBlock: @escaping () -> Void) {
        Self.logger.info("handle avs event: \(description)")

        guard let context = uiMOC else {
            Self.logger.error("Cannot handle event '\(description)' because the UI context is not available.")
            return
        }

        context.performGroupedBlock {
            handlerBlock()
        }
    }

    private func handleEventInContext(
        _ description: String,
        _ handlerBlock: @escaping (NSManagedObjectContext) -> Void
    ) {
        guard let context = uiMOC else {
            Self.logger.error("Cannot handle event '\(description)' because the UI context is not available.")
            return
        }

        context.performGroupedBlock {
            handlerBlock(context)
        }
    }

    /// Handles incoming calls.
    func handleIncomingCall(
        conversationId: String,
        messageTime: Date,
        userId: String,
        clientId: String,
        isVideoCall: Bool,
        shouldRing: Bool,
        conversationType: AVSConversationType
    ) {
        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        let userId = AVSIdentifier.from(
            string: userId,
            isFederationEnabled: isFederationEnabled
        )

        let client = AVSClient(
            userId: userId,
            clientId: clientId
        )

        handleEvent("incoming-call") {
            let isDegraded = self.isDegraded(conversationId: conversationId)
            let callState = CallState.incoming(isVideo: isVideoCall, shouldRing: shouldRing, degraded: isDegraded)
            let members = [AVSCallMember(client: client)]

            self.createSnapshot(
                callState: callState,
                members: members,
                callStarter: client.avsIdentifier(isFederationEnabled: self.isFederationEnabled),
                video: isVideoCall,
                for: conversationId,
                conversationType: conversationType
            )
            self.handle(callState: callState, conversationId: conversationId)
        }
    }

    /// Handles missed calls.
    func handleMissedCall(
        conversationId: String,
        messageTime: Date,
        userId: String,
        isVideoCall: Bool
    ) {
        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        let userId = AVSIdentifier.from(
            string: userId,
            isFederationEnabled: isFederationEnabled
        )

        handleEvent("missed-call") {
            self.missed(
                conversationId: conversationId,
                userId: userId,
                timestamp: messageTime,
                isVideoCall: isVideoCall
            )
        }
    }

    /// Handles answered calls.
    func handleAnsweredCall(conversationId: String) {
        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        handleEvent("answered-call") {
            let callState = CallState.answered(degraded: self.isDegraded(conversationId: conversationId))
            self.handle(callState: callState, conversationId: conversationId)
        }
    }

    /// Handles when data channel gets established.
    func handleDataChannelEstablishement(conversationId: String) {
        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        handleEvent("data-channel-established") {
            // Ignore if data channel was established after audio
            if self.callState(conversationId: conversationId) != .established {
                self.handle(callState: .establishedDataChannel, conversationId: conversationId)
            }
        }
    }

    /// Handles established calls.
    func handleEstablishedCall(conversationId: String) {
        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        handleEvent("established-call") {
            // WORKAROUND: the call established handler is called once for every participant in a
            // group call. Until that's no longer the case we must take care to only set establishedDate once.
            if self.callState(conversationId: conversationId) != .established {
                self.establishedDate = Date()
            }

            if self.videoState(conversationId: conversationId) == .started {
                self.avsWrapper.setVideoState(conversationId: conversationId, videoState: .started)
            }

            self.handle(callState: .established, conversationId: conversationId)
        }
    }

    /// Handles ended calls
    /// If the user answers on the different device, we receive a `WCALL_REASON_ANSWERED_ELSEWHERE` followed by a
    /// `WCALL_REASON_NORMAL` once the call ends.
    ///
    /// If the user leaves an ongoing group conversation or an incoming group call times out, we receive a
    /// `WCALL_REASON_STILL_ONGOING` followed by a `WCALL_REASON_NORMAL` once the call ends.
    ///
    /// If messageTime is set to 0, the event wasn't caused by a message therefore we don't have a serverTimestamp.

    func handleCallEnd(
        reason: CallClosedReason,
        conversationId: String,
        messageTime: Date?,
        userId: String
    ) {
        guard isEnabled else { return }

        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        let userId = AVSIdentifier.from(
            string: userId,
            isFederationEnabled: isFederationEnabled
        )

        handleEvent("closed-call") {
            self.handle(
                callState: .terminating(reason: reason),
                conversationId: conversationId,
                messageTime: messageTime,
                userId: userId
            )
        }
    }

    /// Handles call metrics.
    func handleCallMetrics(conversationId: String, metrics: String) {
        let metricsData = Data(metrics.utf8)
        WireLogger.avs.info("Calling metrics: \(String(decoding: metricsData, as: UTF8.self))")
    }

    /// Handle requests for refreshing the calling configuration.
    func handleCallConfigRefreshRequest() {
        handleEvent("request-call-config") {
            self.requestCallConfig()
        }
    }

    /// Handles sending call messages
    func handleCallMessageRequest(
        token: WireCallMessageToken,
        conversationId: String,
        senderUserId: String,
        senderClientId: String,
        targets: AVSClientList?,
        data: Data,
        overMLSSelfConversation: Bool = false
    ) {
        guard isEnabled else { return }

        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        let senderUserId = AVSIdentifier.from(
            string: senderUserId,
            isFederationEnabled: isFederationEnabled
        )

        handleEventInContext("send-call-message") { managedObjectContext in
            let selfUser = ZMUser.selfUser(in: managedObjectContext)

            guard
                selfUser.avsIdentifier == senderUserId,
                selfUser.selfClient()?.remoteIdentifier == senderClientId
            else {
                Self.logger.warn("Received request to send calling message from non self user and/or client")
                return
            }

            self.send(
                token: token,
                conversationId: conversationId,
                targets: targets,
                data: data,
                dataLength: data.count,
                overMLSSelfConversation: overMLSSelfConversation
            )
        }
    }

    /// Called when AVS is ready.
    func setCallReady(version: Int32) {
        Self.logger.debug("wcall intialized with protocol version: \(version)")
        handleEvent("call-ready") {
            self.isReady = true
        }
    }

    func handleParticipantChange(
        conversationId: String,
        data: String
    ) {
        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        handleEvent("participant-change") {
            guard let data = data.data(using: .utf8) else {
                Self.logger.info("Invalid participant change data", attributes: .safePublic)
                return
            }

            // Example of `data`
            //  {
            //      "convid": "df371578-65cf-4f07-9f49-c72a49877ae7",
            //      "members": [
            //          {
            //              "userid": "3f49da1d-0d52-4696-9ef3-0dd181383e8a",
            //              "clientid": "24cc758f602fb1f4",
            //              "aestab": 1,
            //              "vrecv": 0,
            //              "muted": 0 // 0 = false, 1 = true
            //          }
            //      ]
            // }

            do {
                let change = try self.decoder.decode(AVSParticipantsChange.self, from: data)
                let members = change.members.map(AVSCallMember.init)
                self.callParticipantsChanged(
                    conversationId: AVSIdentifier.from(
                        string: change.convid,
                        isFederationEnabled: self.isFederationEnabled
                    ),
                    participants: members
                )
            } catch {
                let change = String(decoding: data, as: UTF8.self)
                Self.logger.info("Cannot decode participant change JSON: \(change)", attributes: .safePublic)
            }
        }
    }

    /// Handles audio CBR mode enabling.
    func handleConstantBitRateChange(enabled: Bool) {
        handleEventInContext("cbr-change") {
            let firstEstablishedCall = self.callSnapshots.first {
                $0.value.callState == .established || $0.value.callState == .establishedDataChannel
            }

            if let establishedCall = firstEstablishedCall {
                self.callSnapshots[establishedCall.key] = establishedCall.value.updateConstantBitrate(enabled)
                WireCallCenterCBRNotification(enabled: enabled).post(in: $0.notificationContext)
            }
        }
    }

    /// Stopped when the media stream of a call was ended.
    func handleMediaStopped(conversationId: String) {
        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        handleEvent("media-stopped") {
            self.handle(callState: .mediaStopped, conversationId: conversationId)
        }
    }

    /// This handler is called for 1:1 and conference calls.
    ///
    /// In 1:1 calls, `userId` and `clientId` are the ids of the remote user
    /// In conference calls, since there is multiple remote users, the ids will be "SFT" and should be ignored
    ///
    /// - Parameters:
    ///   - conversationId: the AVSIdentifier of the conversation
    ///   - userId: the remote user's ID for 1:1 calls, defaults to "SFT" for conference calls
    ///   - clientId: the remote user's client ID for 1:1 calls, defaults to "SFT" for conference calls
    ///   - quality: the network quality
    ///
    func handleNetworkQualityChange(
        conversationId: String,
        userId: String,
        clientId: String,
        quality: NetworkQuality
    ) {
        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        handleEventInContext("network-quality-change") {

            // We ignore the `usedId` and `clientID` because we only need to know the network quality

            if let call = self.callSnapshots[conversationId], call.networkQuality != quality {
                self.callSnapshots[conversationId] = call.updateNetworkQuality(quality)
                let notification = WireCallCenterNetworkQualityNotification(
                    conversationId: conversationId,
                    networkQuality: quality
                )
                notification.post(in: $0.notificationContext)
            }
        }
    }

    func handleMuteChange(muted: Bool) {
        handleEventInContext("mute-change") {
            WireCallCenterMutedNotification(muted: muted).post(in: $0.notificationContext)
        }
    }

    func handleClientsRequest(
        conversationId: String,
        completion: @escaping (_ clients: String) -> Void
    ) {
        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        handleClientsRequest(
            conversationId: conversationId,
            completion: completion
        )
    }

    func handleClientsRequest(
        conversationId: AVSIdentifier,
        completion: @escaping (_ clients: String) -> Void
    ) {
        handleEventInContext("request-clients") { [weak self, encoder] context in
            guard let self else { return }

            // Check if this is an MLS conference call
            if conversationType(from: conversationId) == .mlsConference {
                guard
                    let snapshot = callSnapshots[conversationId],
                    let groupIDs = snapshot.groupIDs
                else {
                    Self.logger.error(
                        "Cannot get group IDs for MLS conference",
                        attributes: [.conversationId: conversationId.safeForLoggingDescription]
                    )
                    return
                }

                handleMLSConferenceClientsRequest(
                    conversationId: conversationId,
                    parentGroupID: groupIDs.parent,
                    subconversationGroupID: groupIDs.subconversation,
                    context: context,
                    encoder: encoder,
                    completion: completion
                )
            } else {
                handleNonMLSConferenceClientsRequest(
                    conversationId: conversationId,
                    encoder: encoder,
                    completion: completion
                )
            }
        }
    }

    private func handleMLSConferenceClientsRequest(
        conversationId: AVSIdentifier,
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID,
        context: NSManagedObjectContext,
        encoder: JSONEncoder,
        completion: @escaping (_ clients: String) -> Void
    ) {
        guard let syncContext = context.zm_sync else {
            Self.logger.error("Cannot get sync context for MLS conference")
            return
        }

        syncContext.perform { [weak self] in
            guard
                let self,
                let mlsService = syncContext.mlsService
            else {
                return
            }

            Task {
                do {
                    let conferenceInfo = try await mlsService.generateConferenceInfo(
                        parentGroupID: parentGroupID,
                        subconversationGroupID: subconversationGroupID
                    )

                    self.avsWrapper.setMLSConferenceInfo(
                        conversationId: conversationId,
                        info: conferenceInfo
                    )

                    let clients = conferenceInfo.members.compactMap {
                        AVSClient(
                            member: $0,
                            isFederationEnabled: self.isFederationEnabled
                        )
                    }

                    guard let json = AVSClientList(clients: clients).jsonString(encoder) else {
                        Self.logger.error(
                            "Could not encode MLS client list to JSON",
                            attributes: [.mlsGroupID: parentGroupID.safeForLoggingDescription]
                        )
                        return
                    }

                    completion(json)
                } catch {
                    Self.logger.error(
                        "Failed to generate conference info: \(String(reflecting: error))",
                        attributes: [.conversationId: conversationId.safeForLoggingDescription]
                    )
                }
            }
        }
    }

    private func handleNonMLSConferenceClientsRequest(
        conversationId: AVSIdentifier,
        encoder: JSONEncoder,
        completion: @escaping (_ clients: String) -> Void
    ) {
        // This handler is called once per call, but the participants may be
        // added or removed from the conversation during this time. Therefore
        // we store the completion so that it can be re-invoked with an updated
        // client list.
        clientsRequestCompletionsByConversationId[conversationId] = completion

        transport?.requestClientsList(conversationId: conversationId) { clients in
            guard let json = AVSClientList(clients: clients).jsonString(encoder) else {
                Self.logger.error(
                    "Could not encode client list to JSON",
                    attributes: [.conversationId: conversationId.safeForLoggingDescription]
                )
                return
            }

            completion(json)
        }
    }

    func handleSFTCallMessageRequest(token: WireCallMessageToken, url: String, data: Data) {
        handleEvent("send-sft-call-message") {
            self.sendSFT(token: token, url: url, data: data)
        }
    }

    func handleActiveSpeakersChange(
        conversationId: String,
        data: String
    ) {
        let conversationId = AVSIdentifier.from(
            string: conversationId,
            isFederationEnabled: isFederationEnabled
        )

        // TODO: [WPB-9604]: - refactor to avoid processing call data on the UI context
        handleEventInContext("active-speakers-change") {

            guard let data = data.data(using: .utf8) else {
                Self.logger.error("Invalid active speakers data", attributes: .safePublic)
                return
            }

            // Example of `data`
            //  {
            //      "audio_levels": [
            //          {
            //              "userid": "3f49da1d-0d52-4696-9ef3-0dd181383e8a",
            //              "clientid": "24cc758f602fb1f4",
            //              "audio_level": 100,
            //              "audio_level_now": 100
            //          }
            //      ]
            // }

            do {
                let change = try self.decoder.decode(AVSActiveSpeakersChange.self, from: data)

                if let call = self.callSnapshots[conversationId] {

                    self.callSnapshots[conversationId] = call.updateActiveSpeakers(change.activeSpeakers)

                    guard self.isSignificantActiveSpeakersChange(
                        change: change,
                        in: call
                    ) else {
                        return
                    }

                    WireCallCenterActiveSpeakersNotification().post(in: $0.notificationContext)
                }
            } catch {
                Self.logger.error("Cannot decode active speakers change JSON", attributes: .safePublic)
            }
        }
    }

    private func isSignificantActiveSpeakersChange(
        change: AVSActiveSpeakersChange,
        in call: CallSnapshot
    ) -> Bool {
        let currentSpeakers = Set(call.activeSpeakers)
        let newSpeakers = Set(change.activeSpeakers)

        var isSignificant = false

        for newSpeaker in newSpeakers {
            let currentSpeaker = currentSpeakers.first {
                let currentSpeakerID = $0.client.avsIdentifier(isFederationEnabled: isFederationEnabled)
                let newSpeakerID = newSpeaker.client.avsIdentifier(isFederationEnabled: isFederationEnabled)
                return currentSpeakerID == newSpeakerID
            }

            if let currentSpeaker {
                let stoppedTalking = currentSpeaker.audioLevelNow > 0 && newSpeaker.audioLevelNow == 0
                let startedTalking = currentSpeaker.audioLevelNow == 0 && newSpeaker.audioLevelNow > 0

                isSignificant = stoppedTalking || startedTalking
            } else {
                isSignificant = newSpeaker.audioLevelNow > 0
            }
        }

        return isSignificant
    }

    func handleNewEpochRequest(conversationID: String) {
        let conversationID = AVSIdentifier.from(
            string: conversationID,
            isFederationEnabled: isFederationEnabled
        )

        handleEvent("new-epoch-request") {
            guard
                let viewContext = self.uiMOC,
                let syncContext = viewContext.zm_sync,
                let snapshot = self.callSnapshots[conversationID],
                let groupIDs = snapshot.groupIDs
            else {
                return
            }

            syncContext.perform {
                guard let mlsService = syncContext.mlsService else {
                    return
                }

                Task {
                    do {
                        try await mlsService.generateNewEpoch(groupID: groupIDs.subconversation)
                    } catch {
                        Self.logger.error("failed to generate new epoch: \(String(reflecting: error))")
                    }
                }
            }
        }
    }
}

extension AVSIdentifier: @retroactive SafeForLoggingStringConvertible {

    public var safeForLoggingDescription: String {
        "\(identifier.safeForLoggingDescription) - \(String(describing: domain?.readableHash))"
    }

}
