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

import avs
import Foundation

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

        let updatedCallState = previousSnapshot.callState.update(isConversationDegraded: changeInfo.conversation.isDegraded)

        if updatedCallState != previousSnapshot.callState {
            callSnapshots[conversationId] = previousSnapshot.update(with: updatedCallState)

            if let context = uiMOC, let callerId = initiatorForCall(conversationId: conversationId) {
                let notification = WireCallCenterCallStateNotification(context: context,
                                                                       callState: updatedCallState,
                                                                       conversationId: conversationId,
                                                                       callerId: callerId,
                                                                       messageTime: Date(),
                                                                       previousCallState: previousSnapshot.callState)
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

        guard
            let avsIdentifier = conversation.avsIdentifier,
            let context = conversation.managedObjectContext,
            changeInfo.messageProtocolChanged,
            conversation.messageProtocol == .mls,
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

        if changeInfo.isDeletedChanged && changeInfo.conversation.isDeletedRemotely {
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

        guard let context = self.uiMOC else {
            Self.logger.error("Cannot handle event '\(description)' because the UI context is not available.")
            return
        }

        context.performGroupedBlock {
            handlerBlock()
        }
    }

    private func handleEventInContext(_ description: String, _ handlerBlock: @escaping (NSManagedObjectContext) -> Void) {
        guard let context = self.uiMOC else {
            Self.logger.error("Cannot handle event '\(description)' because the UI context is not available.")
            return
        }

        context.performGroupedBlock {
            handlerBlock(context)
        }
    }

    /// Handles incoming calls.
    func handleIncomingCall(conversationId: AVSIdentifier, messageTime: Date, client: AVSClient, isVideoCall: Bool, shouldRing: Bool, conversationType: AVSConversationType) {
        handleEvent("incoming-call") {
            let isDegraded = self.isDegraded(conversationId: conversationId)
            let callState = CallState.incoming(video: isVideoCall, shouldRing: shouldRing, degraded: isDegraded)
            let members = [AVSCallMember(client: client)]

            self.createSnapshot(callState: callState, members: members, callStarter: client.avsIdentifier, video: isVideoCall, for: conversationId, conversationType: conversationType)
            self.handle(callState: callState, conversationId: conversationId)
        }
    }

    /// Handles missed calls.
    func handleMissedCall(conversationId: AVSIdentifier, messageTime: Date, userId: AVSIdentifier, isVideoCall: Bool) {
        handleEvent("missed-call") {
            self.missed(conversationId: conversationId, userId: userId, timestamp: messageTime, isVideoCall: isVideoCall)
        }
    }

    /// Handles answered calls.
    func handleAnsweredCall(conversationId: AVSIdentifier) {
        handleEvent("answered-call") {
            let callState = CallState.answered(degraded: self.isDegraded(conversationId: conversationId))
            self.handle(callState: callState, conversationId: conversationId)
        }
    }

    /// Handles when data channel gets established.
    func handleDataChannelEstablishement(conversationId: AVSIdentifier) {
        handleEvent("data-channel-established") {
            // Ignore if data channel was established after audio
            if self.callState(conversationId: conversationId) != .established {
                self.handle(callState: .establishedDataChannel, conversationId: conversationId)
            }
        }
    }

    /// Handles established calls.
    func handleEstablishedCall(conversationId: AVSIdentifier) {
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

    /**
     * Handles ended calls
     * If the user answers on the different device, we receive a `WCALL_REASON_ANSWERED_ELSEWHERE` followed by a
     * `WCALL_REASON_NORMAL` once the call ends.
     *
     * If the user leaves an ongoing group conversation or an incoming group call times out, we receive a
     * `WCALL_REASON_STILL_ONGOING` followed by a `WCALL_REASON_NORMAL` once the call ends.
     *
     * If messageTime is set to 0, the event wasn't caused by a message therefore we don't have a serverTimestamp.
     */

    func handleCallEnd(reason: CallClosedReason, conversationId: AVSIdentifier, messageTime: Date?, userId: AVSIdentifier) {
        guard isEnabled else { return }
        handleEvent("closed-call") {
            self.handle(callState: .terminating(reason: reason), conversationId: conversationId, messageTime: messageTime, userId: userId)
        }
    }

    /// Handles call metrics.
    func handleCallMetrics(conversationId: AVSIdentifier, metrics: String) {
        do {
            let metricsData = Data(metrics.utf8)
            let jsonObject = try JSONSerialization.jsonObject(with: metricsData, options: .mutableContainers)
            guard let attributes = jsonObject as? [String: NSObject] else { return }
            analytics?.tagEvent("calling.avs_metrics_ended_call", attributes: attributes)
            WireLogger.avs.info("Calling metrics: \(String(data: metricsData, encoding: .utf8) ?? ""))")
        } catch {
            WireLogger.calling.error("Unable to parse call metrics JSON: \(error)")
        }
    }

    /// Handle requests for refreshing the calling configuration.
    func handleCallConfigRefreshRequest() {
        handleEvent("request-call-config") {
            self.requestCallConfig()
        }
    }

    /// Handles sending call messages
    internal func handleCallMessageRequest(token: WireCallMessageToken,
                                           conversationId: AVSIdentifier,
                                           senderUserId: AVSIdentifier,
                                           senderClientId: String,
                                           targets: AVSClientList?,
                                           data: Data,
                                           overMLSSelfConversation: Bool = false) {

        guard isEnabled else { return }

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

    func handleParticipantChange(conversationId: AVSIdentifier, data: String) {
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
                self.callParticipantsChanged(conversationId: AVSIdentifier.from(string: change.convid), participants: members)
            } catch {
                let change = String(data: data, encoding: .utf8)
                Self.logger.info("Cannot decode participant change JSON: \(String(describing: change))", attributes: .safePublic)
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
    func handleMediaStopped(conversationId: AVSIdentifier) {
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
        conversationId: AVSIdentifier,
        userId: String,
        clientId: String,
        quality: NetworkQuality
    ) {
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

    func handleClientsRequest(conversationId: AVSIdentifier, completion: @escaping (_ clients: String) -> Void) {
        handleEventInContext("request-clients") { [encoder] _ in
            self.transport?.requestClientsList(conversationId: conversationId) { clients in

                guard let json = AVSClientList(clients: clients).jsonString(encoder) else {
                    Self.logger.error("Could not encode client list to JSON")
                    return
                }

                completion(json)
            }
        }
    }

    func handleSFTCallMessageRequest(token: WireCallMessageToken, url: String, data: Data) {
        handleEvent("send-sft-call-message") {
            self.sendSFT(token: token, url: url, data: data)
        }
    }

    func handleActiveSpeakersChange(conversationId: AVSIdentifier, data: String) {
        // TODO [WPB-9604]: - refactor to avoid processing call data on the UI context 
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
                $0.client.avsIdentifier == newSpeaker.client.avsIdentifier
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

    func handleNewEpochRequest(conversationID: AVSIdentifier) {
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
