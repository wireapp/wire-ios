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

import WireLogging
import WireAnalytics
import WireSyncEngine

final class CallEndedAnalyticsController {

    private let contextProvider: ContextProvider
    private let analyticsEventTracker: () -> (any AnalyticsEventTracker)?

    private var eventInfo: EventInfo?
    private var screenSharingStart: Date?
    private var callStateObserverToken: AnyObject!
    private var callParticipantObsererToken: AnyObject!

    private let logger: LoggerProtocol

    init(
        contextProvider: ContextProvider,
        analyticsEventTracker: @escaping () -> (any AnalyticsEventTracker)?,
        logger: LoggerProtocol
    ) {
        self.contextProvider = contextProvider
        self.analyticsEventTracker = analyticsEventTracker
        self.logger = logger

        // TODO: can't we have a protocol instead of using static/class methods?
        callStateObserverToken = WireCallCenterV3.addCallStateObserver(
            observer: self,
            contextProvider: contextProvider
        )
    }

    private func handleIncomingCall(_ conversation: ZMConversation) {
        if let eventInfo {
            logger.error("handleIncomingCall: expected eventInfo to be nil, but is: \(eventInfo)")
        }

        eventInfo = .init(
            conversationType: conversation.conversationType == .group ? .group : .oneOnOne
        )
    }

    private func handleOutgoingCall(_ conversation: ZMConversation) {
        if let eventInfo {
            logger.error("handleOutgoingCall: expected eventInfo to be nil, but is: \(eventInfo)")
        }

        eventInfo = .init(
            callDirection: .outgoing,
            conversationType: conversation.conversationType == .group ? .group : .oneOnOne
        )
    }

    private func handleCallEstablished(_ conversation: ZMConversation) {
        if eventInfo == nil {
            logger.error("handleCallEstablished: expected eventInfo to be non-nil")
            eventInfo = .init()
        }

        callParticipantObsererToken = WireCallCenterV3.addCallParticipantObserver(
            observer: self,
            for: conversation,
            contextProvider: contextProvider
        )
    }

    private func handleCallTerminating(_ reason: CallClosedReason) {
        if eventInfo == nil {
            logger.error("handleCallTerminating: expected eventInfo to be non-nil")
            eventInfo = .init()
        }

        callParticipantObsererToken = nil

        guard let eventInfo else { return }

        let analyticsEventTracker = analyticsEventTracker()
        analyticsEventTracker?.trackEvent(
            .Calling.endedCall(
                deviceModel: eventInfo.deviceModel,
                deviceOS: eventInfo.deviceOS,
                wasScreenShared: !eventInfo.uniqueScreenSharingUsers.isEmpty,
                totalScreenSharingDuration: eventInfo.totalScreenSharingDuration,
                uniqueScreenSharingUsers: eventInfo.uniqueScreenSharingUsers.count,
                callDirection: eventInfo.callDirection,
                callDuration: eventInfo.callDuration(),
                conversationType: eventInfo.conversationType,
                participantCount: eventInfo.participantCount,
                // TODO: make complete
                callEndReason: reason.analyticsValue
            )
        )

        self.eventInfo = nil
    }

}

// MARK: - CallEndedAnalyticsController.EventInfo

private extension CallEndedAnalyticsController {

    struct EventInfo {

        var deviceModel = UIDevice.current.model
        var deviceOS = UIDevice.current.systemVersion
        var callDirection: AnalyticsEvent.Calling.CallDirection = .incoming
        var callStart = Date.now
        var conversationType: ConversationType_ = .oneOnOne
        var totalScreenSharingDuration = 0
        var uniqueScreenSharingUsers = Set<UUID>()
        var participantCount = UInt()

        func callDuration(at callEnd: Date = .now) -> Int {
            Int(round(callEnd.timeIntervalSince(callStart)))
        }
    }

}

// MARK: - CallEndedAnalyticsController + WireCallCenterCallStateObserver

extension CallEndedAnalyticsController: WireCallCenterCallStateObserver {

    func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: any UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        logger.info("callCenterDidChange: \(callState)")

        switch callState {
        case .incoming:
            handleIncomingCall(conversation)
        case .outgoing:
            handleOutgoingCall(conversation)
        case .established:
            handleCallEstablished(conversation)
        case .terminating(let reason):
            handleCallTerminating(reason)
        default:
            break
        }
    }

}

// MARK: - CallEndedAnalyticsController + WireCallCenterCallParticipantObserver

extension CallEndedAnalyticsController: WireCallCenterCallParticipantObserver {

    func callParticipantsDidChange(
        conversation: ZMConversation,
        participants: [CallParticipant]
    ) {
        // if there is anybody sharing the screen take a note and also remember the time if needed
        let screenSharingParticipants = participants
            .filter { participant in participant.state.videoState == .screenSharing }
            .map(\.userId.identifier)
        eventInfo?.uniqueScreenSharingUsers.formUnion(screenSharingParticipants)

        if !screenSharingParticipants.isEmpty {
            screenSharingStart = screenSharingStart ?? .now
        } else if let screenSharingStart {
            // screen sharing just stopped
            let duration = screenSharingStart.distance(to: .now)
            eventInfo?.totalScreenSharingDuration += Int(round(duration))
            self.screenSharingStart = nil
        }
    }

}
