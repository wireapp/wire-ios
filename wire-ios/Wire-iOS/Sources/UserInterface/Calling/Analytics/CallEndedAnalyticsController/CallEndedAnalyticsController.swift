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
import WireAnalytics
import WireLogging
import WireSyncEngine

final class CallEndedAnalyticsController {

    private let contextProvider: ContextProvider
    private let callCenterType: WireCallCenterV3.Type
    private let analyticsEventTracker: () -> (any AnalyticsEventTracker)?

    private var eventInfo: EventInfo?
    private var callStateObserverToken: AnyObject!
    private var callParticipantObsererToken: AnyObject!
    private var setVideoCancellable = Set<AnyCancellable>()

    private let logger: LoggerProtocol

    init(
        contextProvider: ContextProvider,
        callCenterType: WireCallCenterV3.Type,
        toggleVideoPublisher: AnyPublisher<Void, Never>,
        analyticsEventTracker: @escaping () -> (any AnalyticsEventTracker)?,
        logger: LoggerProtocol
    ) {
        self.contextProvider = contextProvider
        self.callCenterType = callCenterType
        self.analyticsEventTracker = analyticsEventTracker
        self.logger = logger

        // TODO: can't we have a protocol instead of using static/class methods? TODO
        self.callStateObserverToken = callCenterType.addCallStateObserver(
            observer: self,
            contextProvider: contextProvider
        )

        toggleVideoPublisher.sink { [weak self] in
            self?.eventInfo?.hasAVSwitchToggled = true
            self?.setVideoCancellable.removeAll()
        }.store(in: &setVideoCancellable)
    }

    private func handleIncomingCall(
        _ conversation: ZMConversation,
        _ isVideoCall: Bool
    ) {
        if let eventInfo {
            logger.error("handleIncomingCall: expected eventInfo to be nil, but is: \(eventInfo)")
        }

        eventInfo = .init(
            conversationType: conversation.conversationType == .group ? .group : .oneOnOne,
            isVideoCall: isVideoCall
        )
    }

    private func handleOutgoingCall(
        _ conversation: ZMConversation,
        _ isVideoCall: Bool
    ) {
        if let eventInfo {
            logger.error("handleOutgoingCall: expected eventInfo to be nil, but is: \(eventInfo)")
        }

        eventInfo = .init(
            callDirection: .outgoing,
            conversationType: conversation.conversationType == .group ? .group : .oneOnOne,
            isVideoCall: isVideoCall
        )
    }

    private func handleCallEstablished(_ conversation: ZMConversation) {
        if eventInfo == nil {
            logger.error("handleCallEstablished: expected eventInfo to be non-nil")
            eventInfo = .init()
        }

        callParticipantObsererToken = callCenterType.addCallParticipantObserver(
            observer: self,
            for: conversation,
            contextProvider: contextProvider
        )
    }

    private func handleCallTerminating(
        _ conversation: ZMConversation,
        _ reason: CallClosedReason
    ) {
        if eventInfo == nil {
            logger.error("handleCallTerminating: expected eventInfo to be non-nil")
            eventInfo = .init()
        }

        callParticipantObsererToken = nil

        guard let eventInfo, let context = conversation.managedObjectContext else { return }

        let (
            isTeamMember,
            conversationSize,
            conversationGuestsTeam,
            conversationGuestsNonTeam,
            conversationServices
        ) = context.performAndWait {
            let isTeamMember = conversation.participants
                .first { $0.isSelfUser }
                .map(\.hasTeam) ?? false
            let conversationSize = conversation.localParticipants.count
            let guestsWithTeam = conversation.participants
                .filter { $0.isGuest(in: conversation) }
                .map(\.hasTeam)
            let conversationGuestsTeam = guestsWithTeam.count { $0 }
            let conversationGuestsNonTeam = guestsWithTeam.count { !$0 }
            let conversationServices = conversation.sortedServiceUsers.count
            return (
                isTeamMember,
                conversationSize,
                conversationGuestsTeam,
                conversationGuestsNonTeam,
                conversationServices
            )
        }

        let analyticsEventTracker = analyticsEventTracker()
        analyticsEventTracker?.trackEvent(
            .Calling.endedCall(
                deviceModel: eventInfo.deviceModel,
                osVersion: eventInfo.osVersion,
                callEndReason: reason.analyticsValue,
                callDetails: .init(
                    wasScreenShared: !eventInfo.uniqueScreenSharingUsers.isEmpty,
                    totalScreenSharingDuration: eventInfo.totalScreenSharingDuration,
                    uniqueScreenSharingUsers: eventInfo.uniqueScreenSharingUsers.count,
                    callDirection: eventInfo.callDirection,
                    callDuration: eventInfo.callDuration(),
                    callParticipantCount: eventInfo.participantCount,
                    conversationServiceCount: conversationServices,
                    hasAVSwitchToggled: eventInfo.hasAVSwitchToggled,
                    isVideoCall: eventInfo.isVideoCall
                ),
                conversationDetails: .init(
                    conversationType: eventInfo.conversationType,
                    conversationSize: conversationSize,
                    conversationGuestsNonTeam: conversationGuestsNonTeam,
                    conversationGuestsTeam: conversationGuestsTeam
                ),
                isTeamMember: isTeamMember
            )
        )

        self.eventInfo = nil
    }

}

// MARK: - CallEndedAnalyticsController.EventInfo

private extension CallEndedAnalyticsController {

    struct EventInfo {

        var deviceModel = UIDevice.current.model
        var osVersion = UIDevice.current.systemVersion
        var callDirection: AnalyticsEvent.Calling.CallDirection = .incoming
        var callStart = Date.now
        var screenSharingStart: Date?
        var conversationType: AnalyticsEvent.Segmentation.Conversation.ConversationType = .oneOnOne
        var totalScreenSharingDuration = 0
        var uniqueScreenSharingUsers = Set<UUID>()
        var participantCount = Int()
        var isVideoCall = false
        var hasAVSwitchToggled = false

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
        case let .incoming(isVideoCall, _, _):
            handleIncomingCall(conversation, isVideoCall)
        case let .outgoing(isVideoCall, _):
            handleOutgoingCall(conversation, isVideoCall)
        case .established:
            handleCallEstablished(conversation)
        case let .terminating(reason):
            handleCallTerminating(conversation, reason)
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
        let eventInfo = eventInfo

        // if there is anybody sharing the screen take a note and also remember the time if needed
        let screenSharingParticipants = participants
            .filter { participant in participant.state.videoState == .screenSharing }
            .map(\.userId.identifier)
        self.eventInfo?.uniqueScreenSharingUsers.formUnion(screenSharingParticipants)

        if !screenSharingParticipants.isEmpty {
            self.eventInfo?.screenSharingStart = eventInfo?.screenSharingStart ?? .now
        } else if let screenSharingStart = eventInfo?.screenSharingStart {
            // screen sharing just stopped
            let duration = screenSharingStart.distance(to: .now)
            self.eventInfo?.totalScreenSharingDuration += Int(round(duration))
            self.eventInfo?.screenSharingStart = nil
        }
    }

}
