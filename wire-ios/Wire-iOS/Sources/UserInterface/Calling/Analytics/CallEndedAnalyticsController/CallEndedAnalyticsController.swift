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

import WireAnalytics
import WireSyncEngine

final class CallEndedAnalyticsController {

    private let contextProvider: ContextProvider
    private let analyticsEventTracker: () -> (any AnalyticsEventTracker)?

    private var callStateObserverToken: AnyObject!
    private var eventInfo: EventInfo?

    init(
        contextProvider: ContextProvider,
        analyticsEventTracker: @escaping () -> (any AnalyticsEventTracker)?
    ) {
        self.contextProvider = contextProvider
        self.analyticsEventTracker = analyticsEventTracker

        callStateObserverToken = WireCallCenterV3.addCallStateObserver(
            observer: self,
            contextProvider: contextProvider
        )
    }

    private func handleCallEstablished() {
        print("wexflwjdksf TODO: start analytics tracking")

        guard eventInfo == nil else {
            return assertionFailure("call established callback before call terminated")
        }

        eventInfo = .init()
    }

    private func handleCallTerminating(_ reason: CallClosedReason) {
        print("wexflwjdksf TODO: send analytics event and reset")

        guard let eventInfo else {
            return assertionFailure("call terminated callback before call established")
        }

        let analyticsEventTracker = analyticsEventTracker()
        analyticsEventTracker?.trackEvent(
            .Calling.endedCall(
                deviceModel: eventInfo.deviceModel,
                deviceOS: eventInfo.deviceOS,
                wasScreenShared: eventInfo.wasScreenShared,
                totalScreenSharingDuration: eventInfo.totalScreenSharingDuration,
                uniqueScreenSharingUsers: eventInfo.uniqueScreenSharingUsers,
                participantCount: eventInfo.participantCount
                // TODO: make complete
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
        var wasScreenShared = false
        var totalScreenSharingDuration = 0
        var uniqueScreenSharingUsers = 0
        var participantCount = UInt()
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

        switch callState {
        case .established:
            handleCallEstablished()
        case .terminating(let reason):
            handleCallTerminating(reason)
        default:
            break
        }
    }

}
