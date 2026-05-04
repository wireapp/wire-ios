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

import WireAnalytics
import WireFoundation
import WireLogging
import WireSyncEngine

final class CallEndedAnalyticsController<CallCenter: WireCallCenterV3> {

    private let contextProvider: ContextProvider
    private let notificationCenter: NotificationCenter
    private let analyticsEventTracker: () -> (any AnalyticsEventTrackerProtocol)?

    private var eventInfos = [UUID: EventInfo]()
    private var callStateObservationToken: AnyObject?
    private var toggleVideoObservationToken: AnyObject?
    private var callParticipantObserverToken: AnyObject?

    private let logger: LoggerProtocol
    private let currentDateProvider: CurrentDateProviding

    init(
        contextProvider: ContextProvider,
        notificationCenter: NotificationCenter,
        analyticsEventTracker: @escaping () -> (any AnalyticsEventTrackerProtocol)?,
        logger: LoggerProtocol,
        currentDateProvider: CurrentDateProviding
    ) {
        self.contextProvider = contextProvider
        self.notificationCenter = notificationCenter
        self.analyticsEventTracker = analyticsEventTracker
        self.logger = logger
        self.currentDateProvider = currentDateProvider

        setupObservations()
    }

    deinit {
        let notificationCenter = notificationCenter
        if let toggleVideoObservationToken {
            notificationCenter.removeObserver(toggleVideoObservationToken)
        }
    }

    private func setupObservations() {

        callStateObservationToken = CallCenter.addCallStateObserver(
            observer: self,
            contextProvider: contextProvider
        )

        toggleVideoObservationToken = notificationCenter.addObserver(
            forName: WireCallCenterV3.didToggleVideoNotification, object: .none, queue: .none
        ) { [weak self] notification in
            self?.handleToggleVideoNotification(notification)
        }
    }

    private func handleIncomingCall(
        _ conversation: ZMConversation,
        _ isVideoCall: Bool
    ) {
        if let eventInfo = eventInfos[conversation.remoteIdentifier] {
            logger.error("handleIncomingCall: expected eventInfo to be nil, but is: \(eventInfo)")
        }

        eventInfos[conversation.remoteIdentifier] = .init(
            conversationID: conversation.avsIdentifier,
            conversationType: conversation.conversationType == .group ? .group : .oneOnOne,
            isVideoCall: isVideoCall
        )
    }

    private func handleOutgoingCall(
        _ conversation: ZMConversation,
        _ isVideoCall: Bool
    ) {
        if let eventInfo = eventInfos[conversation.remoteIdentifier] {
            logger.error("handleOutgoingCall: expected eventInfo to be nil, but is: \(eventInfo)")
        }

        eventInfos[conversation.remoteIdentifier] = .init(
            callDirection: .outgoing,
            conversationID: conversation.avsIdentifier,
            conversationType: conversation.conversationType == .group ? .group : .oneOnOne,
            isVideoCall: isVideoCall
        )
    }

    private func handleCallEstablished(_ conversation: ZMConversation) {
        if eventInfos[conversation.remoteIdentifier] == nil {
            logger.error("handleCallEstablished: expected eventInfo to be non-nil")
            eventInfos[conversation.remoteIdentifier] = .init(callStart: currentDateProvider.now)
        }

        eventInfos[conversation.remoteIdentifier]?.callStart = currentDateProvider.now

        callParticipantObserverToken = CallCenter.addCallParticipantObserver(
            observer: self,
            for: conversation,
            contextProvider: contextProvider
        )
    }

    private func handleToggleVideoNotification(_ notification: Notification) {
        guard
            let conversationID = notification.userInfo?[CallCenter.conversationIDUserInfoKey] as? AVSIdentifier,
            conversationID == eventInfos[conversationID.identifier]?.conversationID
        else { return }

        eventInfos[conversationID.identifier]?.hasAVSwitchToggled = true

        // unsubscribe since we only want to know if the self user toggled the video at least once
        toggleVideoObservationToken.map { notificationCenter.removeObserver($0) }
        toggleVideoObservationToken = nil
    }

    private func handleCallTerminating(
        _ conversation: ZMConversation,
        _ reason: CallClosedReason
    ) {
        if eventInfos[conversation.remoteIdentifier] == nil {
            logger.error("handleCallTerminating: expected eventInfo to be non-nil")
            return
        }

        callParticipantObserverToken = nil

        guard
            let eventInfo = eventInfos[conversation.remoteIdentifier],
            let context = conversation.managedObjectContext
        else { return }

        let (
            isTeamMember,
            conversationSize,
            conversationGuestsTeam,
            conversationGuestsNonTeam,
            conversationServices
        ) = context.performAndWait {

            let isTeamMember = ZMUser.selfUser(in: context).hasTeam

            let conversationSize = conversation.localParticipants.count

            let guestsHasTeam = conversation.participants
                .filter { $0.isGuest(in: conversation) }
                .map(\.hasTeam)
            let conversationGuestsTeam = guestsHasTeam.count { $0 }
            let conversationGuestsNonTeam = guestsHasTeam.count { !$0 }
            let conversationServices = conversation.sortedApps.count

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
                callEndReason: .init(reason),
                callDetails: .init(
                    wasScreenShared: !eventInfo.uniqueScreenSharingUsers.isEmpty,
                    totalScreenSharingDuration: Int(ceil(eventInfo.totalScreenSharingDuration)),
                    uniqueScreenSharingUsers: eventInfo.uniqueScreenSharingUsers.count,
                    callDirection: eventInfo.callDirection,
                    callDuration: eventInfo.callDuration(at: currentDateProvider.now),
                    callParticipantCount: eventInfo.participants.count,
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

        eventInfos[conversation.remoteIdentifier] = nil
    }

}

// MARK: - CallEndedAnalyticsController.EventInfo

private extension CallEndedAnalyticsController {

    struct EventInfo {

        var callDirection: AnalyticsEvent.Calling.CallDirection = .incoming
        var callStart: Date?
        var screenSharingStart: Date?
        var conversationID: AVSIdentifier?
        var conversationType: AnalyticsEvent.Segmentation.Conversation.ConversationType = .oneOnOne
        var totalScreenSharingDuration = TimeInterval()
        var uniqueScreenSharingUsers = Set<UUID>()
        var participants = Set<UUID>()
        var isVideoCall = false
        var hasAVSwitchToggled = false

        func callDuration(at callEnd: Date) -> Int {
            guard let callStart else { return 0 }
            return Int(round(callEnd.timeIntervalSince(callStart)))
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
        case let .incoming(isVideoCall, true, _):
            handleIncomingCall(conversation, isVideoCall)
        case .answered:
            handleIncomingCall(conversation, false)
        case let .outgoing(isVideoCall, _):
            handleOutgoingCall(conversation, isVideoCall)
        case .established:
            handleCallEstablished(conversation)
        case let .terminating(reason):
            handleCallTerminating(conversation, reason)
        case .mediaStopped, .incoming(_, shouldRing: false, _):
            handleCallTerminating(conversation, .stillOngoing)
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
        let eventInfo = eventInfos[conversation.remoteIdentifier]

        let callParticipants = participants
            .map(\.userId.identifier)
        eventInfos[conversation.remoteIdentifier]?.participants.formUnion(callParticipants)

        let screenSharingParticipants = participants
            .filter { participant in participant.state.videoState == .screenSharing }
            .map(\.userId.identifier)
        eventInfos[conversation.remoteIdentifier]?.uniqueScreenSharingUsers.formUnion(screenSharingParticipants)

        // if there is anybody sharing the screen take a note and also remember the time if needed
        if !screenSharingParticipants.isEmpty {
            eventInfos[conversation.remoteIdentifier]?.screenSharingStart = eventInfo?
                .screenSharingStart ?? currentDateProvider.now
        } else if let screenSharingStart = eventInfo?.screenSharingStart {
            // screen sharing just stopped
            let duration = screenSharingStart.distance(to: currentDateProvider.now)
            eventInfos[conversation.remoteIdentifier]?.totalScreenSharingDuration += duration
            eventInfos[conversation.remoteIdentifier]?.screenSharingStart = nil
        }
    }

}
