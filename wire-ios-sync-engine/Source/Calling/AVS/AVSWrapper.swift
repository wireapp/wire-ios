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

import avs
import Foundation

private let zmLog = ZMSLog(tag: "calling")

/// The type of objects that can provide an interface to calling APIs.
/// This provides strong typing, dependency injection and better testing.

public protocol AVSWrapperType {
    init(userId: AVSIdentifier, clientId: String, observer: UnsafeMutableRawPointer?, isFederationEnabled: Bool)
    func startCall(
        conversationId: AVSIdentifier,
        callType: AVSCallType,
        conversationType: AVSConversationType,
        useCBR: Bool
    ) -> Bool
    func answerCall(conversationId: AVSIdentifier, callType: AVSCallType, useCBR: Bool) -> Bool
    func endCall(conversationId: AVSIdentifier)
    func rejectCall(conversationId: AVSIdentifier)
    func close()
    func received(callEvent: CallEvent, conversationType: AVSConversationType) -> CallError?
    func setVideoState(conversationId: AVSIdentifier, videoState: VideoState)
    func handleResponse(httpStatus: Int, reason: String, context: WireCallMessageToken)
    func handleSFTResponse(data: Data?, context: WireCallMessageToken)
    func update(callConfig: String?, httpStatusCode: Int)
    func requestVideoStreams(_ videoStreams: AVSVideoStreams, conversationId: AVSIdentifier)

    /// Let AVS know that we are batch-processing a stream of notifications.
    /// This method should be called before processing with `isProcessingNotifications` set to `true` as well as
    /// after processing has been completed with `isProcessingNotifications` set to `false`.
    func notify(isProcessingNotifications isProcessing: Bool)
    func networkInterfaceChanged()

    /// Inform AVS whether live syncing is paused.
    ///
    /// Pass `true` when the app is active but live syncing is not ongoing
    /// (for example, when the app is in the background or network connectivity is lost),
    /// and `false` when the app is active and live syncing can resume.
    func setLiveSyncPaused(_ paused: Bool)

    func setMLSConferenceInfo(conversationId: AVSIdentifier, info: MLSConferenceInfo)
    var isMuted: Bool { get set }
}

/// An object that provides an interface to the AVS APIs.
public final class AVSWrapper: AVSWrapperType {

    /// The wrapped `wcall` instance.
    private let handle: UInt32
    private let encoder = JSONEncoder()
    private let isFederationEnabled: Bool

    // MARK: - Initialization

    /// Initializes avs.
    private static var initialize: () -> Void = {
        let resultValue = wcall_init(WCALL_ENV_DEFAULT)
        if resultValue != 0 {
            fatal("Failed to initialise AVS (error code: \(resultValue))")
        }
        return {}
    }()

    private static let logger = Logger(subsystem: "VoIP Push", category: "AVSWrapper")

    /// Creates the wrapper around `wcall`.
    /// - parameter userId: The identifier of the user that owns the calling center.
    /// - parameter clientId: The identifier of the current client (this device).
    /// - parameter observer: The raw pointer to the object that will receive events from AVS.
    /// This must be a pointer to a `WireCallCenterV3` object. If it isn't, the notifications
    /// won't be handled.
    public required init(
        userId: AVSIdentifier,
        clientId: String,
        observer: UnsafeMutableRawPointer?,
        isFederationEnabled: Bool
    ) {
        Self.logger.trace("init")
        defer { Self.logger.trace("init finished") }

        self.isFederationEnabled = isFederationEnabled

        AVSWrapper.initialize()

        self.handle = wcall_create(
            userId.serialized,
            clientId,
            readyHandler,
            sendCallMessageHandler,
            sendSFTCallMessageHandler,
            incomingCallHandler,
            missedCallHandler,
            answeredCallHandler,
            establishedCallHandler,
            closedCallHandler,
            callMetricsHandler,
            requestCallConfigHandler,
            constantBitRateChangeHandler,
            videoStateChangeHandler,
            observer
        )

        wcall_set_data_chan_estab_handler(handle, dataChannelEstablishedHandler)
        let timerIntervalInSeconds: Int32 = 5
        wcall_set_network_quality_handler(handle, networkQualityHandler, timerIntervalInSeconds, observer)
        wcall_set_media_stopped_handler(handle, mediaStoppedChangeHandler)
        wcall_set_mute_handler(handle, muteChangeHandler, observer)
        wcall_set_participant_changed_handler(handle, callParticipantHandler, observer)
        wcall_set_req_clients_handler(handle, requestClientsHandler)
        wcall_set_active_speaker_handler(handle, activeSpeakersHandler)
        wcall_set_req_new_epoch_handler(handle, requestNewEpochHandler)
    }

    // MARK: - Convenience Methods

    public var isMuted: Bool {
        get { wcall_get_mute(handle) != 0 }
        set { wcall_set_mute(handle, newValue ? 1 : 0) }
    }

    /// Requests AVS to initiate a call.
    public func startCall(
        conversationId: AVSIdentifier,
        callType: AVSCallType,
        conversationType: AVSConversationType,
        useCBR: Bool
    ) -> Bool {
        let didStart = wcall_start(
            handle,
            conversationId.serialized,
            callType.rawValue,
            conversationType.rawValue,
            useCBR ? 1 : 0
        )
        return didStart == 0
    }

    /// Marks the call as answered in AVS.
    public func answerCall(
        conversationId: AVSIdentifier,
        callType: AVSCallType,
        useCBR: Bool
    ) -> Bool {
        let didAnswer = wcall_answer(
            handle,
            conversationId.serialized,
            callType.rawValue,
            useCBR ? 1 : 0
        )
        return didAnswer == 0
    }

    /// Marks the call as ended in AVS.
    public func endCall(conversationId: AVSIdentifier) {
        wcall_end(handle, conversationId.serialized)
    }

    /// Marks the call as rejected in AVS.
    public func rejectCall(conversationId: AVSIdentifier) {
        wcall_reject(handle, conversationId.serialized)
    }

    /// Closes the `wcall` handler. This object becomes invalid after this method is called.
    public func close() {
        wcall_destroy(handle)
    }

    /// Changes the video state in AVS for the given conversation.
    public func setVideoState(conversationId: AVSIdentifier, videoState: VideoState) {
        wcall_set_video_send_state(handle, conversationId.serialized, videoState.rawValue)
    }

    /// Passes the response of the calling config request to AVS.
    public func handleResponse(httpStatus: Int, reason: String, context: WireCallMessageToken) {
        wcall_resp(handle, Int32(httpStatus), "", context)
    }

    /// Passes the response of the SFT calling config request to AVS.
    public func handleSFTResponse(data: Data?, context: WireCallMessageToken) {
        let error: Int32
        let buffer: Data

        if let data {
            error = 0
            buffer = data
        } else {
            error = EPROTO
            buffer = Data(count: 0)
        }
        buffer.withUnsafeBytes {
            guard let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress else {
                return
            }
            wcall_sft_resp(handle, error, baseAddress, buffer.count, context)
        }
    }

    /// Notifies AVS that we received a remote event.
    public func received(callEvent: CallEvent, conversationType: AVSConversationType) -> CallError? {
        var result: CallError?

        callEvent.data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            guard let bytes = pointer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            let currentTime = UInt32(callEvent.currentTimestamp.timeIntervalSince1970)
            let serverTime = UInt32(callEvent.serverTimestamp.timeIntervalSince1970)
            zmLog.debug("wcall_recv_msg: currentTime = \(currentTime), serverTime = \(serverTime)")
            // An OTR call-type message has been received,
            // curr_time is the timestamp (synced as close as possible)
            // msg_time is the backend timestamp of when the message was received
            // to the backend time when this function is called.
            result = CallError(wcall_error: wcall_recv_msg(
                handle,
                bytes,
                callEvent.data.count,
                currentTime,
                serverTime,
                callEvent.conversationId.serialized,
                callEvent.userId.serialized,
                callEvent.clientId,
                conversationType.rawValue
            ))
        }

        return result
    }

    /// Updates the calling config.
    public func update(callConfig: String?, httpStatusCode: Int) {
        wcall_config_update(handle, httpStatusCode == 200 ? 0 : EPROTO, callConfig ?? "")
    }

    /// Requests AVS to load a list of video streams
    /// - Parameters:
    ///   - videoStreams: The payload containing a list of clients for which to load video
    ///   - conversationId: The conversation identifier linked to the call
    public func requestVideoStreams(_ videoStreams: AVSVideoStreams, conversationId: AVSIdentifier) {
        wcall_request_video_streams(handle, conversationId.serialized, 0, videoStreams.jsonString(encoder))
    }

    public func notify(isProcessingNotifications isProcessing: Bool) {
        wcall_process_notifications(handle, isProcessing ? 1 : 0)
    }

    public func setLiveSyncPaused(_ paused: Bool) {
        wcall_set_background(handle, paused ? 1 : 0)
    }

    public func networkInterfaceChanged() {
        wcall_network_changed()
    }

    /// Set the MLS conference info for a given conversation.
    ///
    /// - Parameters:
    ///   - conversationId: The conversation hosting the MLS conference.
    ///   - info: The MLS conference info.

    public func setMLSConferenceInfo(
        conversationId: AVSIdentifier,
        info: MLSConferenceInfo
    ) {
        let clients = info.members.compactMap {
            AVSClient(
                member: $0,
                isFederationEnabled: isFederationEnabled
            )
        }

        let clientList = AVSClientList(clients: clients)

        guard let clientListJSON = clientList.jsonString() else {
            return
        }

        wcall_set_epoch_info(
            handle,
            conversationId.serialized,
            UInt32(info.epoch),
            clientListJSON,
            info.keyData.base64EncodedString()
        )
    }

    // MARK: - C Callback Handlers

    private let constantBitRateChangeHandler: Handler.ConstantBitRateChange = { _, _, enabledFlag, contextRef in
        AVSWrapper.withCallCenter(contextRef, enabledFlag) {
            $0.handleConstantBitRateChange(enabled: $1)
        }
    }

    private let videoStateChangeHandler: Handler.VideoStateChange = { _, _, _, _, _ in
        // Video state changes are now communicated through the json payload of the call participant handler.
    }

    private let incomingCallHandler: Handler
        .IncomingCall =
        { conversationId, messageTime, userId, clientId, isVideoCall, shouldRing, conversationType, contextRef in
            let logger = Logger(subsystem: "VoIP Push", category: "AVSWrapper")
            logger.trace("incoming call handler")
            AVSWrapper.withCallCenter(
                contextRef,
                conversationId,
                messageTime,
                userId,
                clientId,
                isVideoCall,
                shouldRing,
                conversationType
            ) {
                $0.handleIncomingCall(
                    conversationId: $1,
                    messageTime: $2,
                    userId: $3,
                    clientId: $4,
                    isVideoCall: $5,
                    shouldRing: $6,
                    conversationType: $7
                )
            }
        }

    private let missedCallHandler: Handler
        .MissedCall = { conversationId, messageTime, userId, _, isVideoCall, contextRef in
            zmLog.debug("missedCallHandler: messageTime = \(messageTime)")
            let nonZeroMessageTime: UInt32 = messageTime != 0 ? messageTime : UInt32(Date().timeIntervalSince1970)

            AVSWrapper.withCallCenter(contextRef, conversationId, nonZeroMessageTime, userId, isVideoCall) {
                $0.handleMissedCall(
                    conversationId: $1,
                    messageTime: $2,
                    userId: $3,
                    isVideoCall: $4
                )
            }
        }

    private let answeredCallHandler: Handler.AnsweredCall = { conversationId, contextRef in
        AVSWrapper.withCallCenter(contextRef, conversationId) {
            $0.handleAnsweredCall(conversationId: $1)
        }
    }

    private let dataChannelEstablishedHandler: Handler.DataChannelEstablished = { conversationId, _, _, contextRef in
        AVSWrapper.withCallCenter(contextRef, conversationId) {
            $0.handleDataChannelEstablishement(conversationId: $1)
        }
    }

    private let establishedCallHandler: Handler.CallEstablished = { conversationId, _, _, contextRef in
        AVSWrapper.withCallCenter(contextRef, conversationId) {
            $0.handleEstablishedCall(conversationId: $1)
        }
    }

    private let closedCallHandler: Handler.CloseCall = { reason, conversationId, messageTime, userId, _, contextRef in
        zmLog.debug("closedCallHandler: messageTime = \(messageTime)")
        let nonZeroMessageTime: UInt32 = messageTime != 0 ? messageTime : UInt32(Date().timeIntervalSince1970)

        AVSWrapper.withCallCenter(contextRef, reason, conversationId, nonZeroMessageTime, userId) {
            $0.handleCallEnd(
                reason: $1,
                conversationId: $2,
                messageTime: $3,
                userId: $4
            )
        }
    }

    private let callMetricsHandler: Handler.CallMetrics = { conversationId, metrics, contextRef in
        AVSWrapper.withCallCenter(contextRef, conversationId, metrics) {
            $0.handleCallMetrics(conversationId: $1, metrics: $2)
        }
    }

    private let requestCallConfigHandler: Handler.CallConfigRefresh = { handle, contextRef in
        zmLog.debug("AVS: requestCallConfigHandler \(String(describing: handle)) \(String(describing: contextRef))")
        return AVSWrapper.withCallCenter(contextRef) {
            $0.handleCallConfigRefreshRequest()
        }
    }

    private let readyHandler: Handler.CallReady = { version, contextRef in
        AVSWrapper.withCallCenter(contextRef) {
            $0.setCallReady(version: version)
        }
    }

    private let sendCallMessageHandler: Handler
        .CallMessageSend =
        { token, conversationId, senderUserId, senderClientId, targetsCString, _, data, dataLength, _, myClientsOnly, contextRef in
            guard let token else {
                return EINVAL
            }

            let bytes = UnsafeBufferPointer<UInt8>(start: data, count: dataLength)
            let transformedData = Data(buffer: bytes)

            let targets = targetsCString
                .flatMap { String(cString: $0)?.data(using: .utf8) }
                .flatMap { AVSClientList($0) }

            return AVSWrapper.withCallCenter(contextRef, conversationId, senderUserId, senderClientId) {
                $0.handleCallMessageRequest(
                    token: token,
                    conversationId: $1,
                    senderUserId: $2,
                    senderClientId: $3,
                    targets: targets,
                    data: transformedData,
                    overMLSSelfConversation: myClientsOnly == 1
                )
            }
        }

    private let callParticipantHandler: Handler.CallParticipantChange = { conversationIdRef, json, contextRef in
        AVSWrapper.withCallCenter(contextRef, json, conversationIdRef) {
            $0.handleParticipantChange(conversationId: $2, data: $1)
        }
    }

    private let mediaStoppedChangeHandler: Handler.MediaStoppedChange = { conversationIdRef, contextRef in
        AVSWrapper.withCallCenter(contextRef, conversationIdRef) {
            $0.handleMediaStopped(conversationId: $1)
        }
    }

    private let networkQualityHandler: Handler
        .NetworkQualityChange = { conversationIdRef, userIdRef, clientIdRef, quality, _, _, _, contextRef in
            AVSWrapper.withCallCenter(contextRef, conversationIdRef, userIdRef, clientIdRef, quality) {
                // For conference calls, userId and clientId will be respectively "sft" and "SFT".
                // This means we cannot create an AVSIdentifier for the userId, because we intentionally crash when the
                // identifier isn't formatted as expected.
                // Instead, we pass the values as Strings and let the handler process them
                $0.handleNetworkQualityChange(
                    conversationId: $1,
                    userId: $2,
                    clientId: $3,
                    quality: $4
                )
            }
        }

    private let muteChangeHandler: Handler.MuteChange = { muted, contextRef in
        AVSWrapper.withCallCenter(contextRef, muted) {
            $0.handleMuteChange(muted: $1)
        }
    }

    private let requestClientsHandler: Handler.RequestClients = { handle, conversationIdRef, contextRef in // thread 11
        AVSWrapper.withCallCenter(contextRef, conversationIdRef) { (callCenter, conversationId: String) in
            let completion: (String) -> Void = { (clients: String) in
                wcall_set_clients_for_conv(handle, conversationIdRef, clients)
            }

            callCenter.handleClientsRequest(
                conversationId: conversationId,
                completion: completion
            )
        }
    }

    private let sendSFTCallMessageHandler: Handler.SFTCallMessageSend = { token, url, data, dataLength, contextRef in
        guard let token else { return EINVAL }

        let bytes = UnsafeBufferPointer<UInt8>(start: data, count: dataLength)
        let transformedData = Data(buffer: bytes)

        return AVSWrapper.withCallCenter(contextRef, url) {
            $0.handleSFTCallMessageRequest(token: token, url: $1, data: transformedData)
        }
    }

    private let activeSpeakersHandler: Handler.ActiveSpeakersChange = { _, conversationIdRef, json, contextRef in
        AVSWrapper.withCallCenter(contextRef, conversationIdRef, json) {
            $0.handleActiveSpeakersChange(conversationId: $1, data: $2)
        }
    }

    private let requestNewEpochHandler: Handler.RequestNewEpoch = { _, conversationIdRef, contextRef in
        AVSWrapper.withCallCenter(contextRef, conversationIdRef) { (callCenter, conversationID: String) in
            callCenter.handleNewEpochRequest(conversationID: conversationID)
        }
    }

}
