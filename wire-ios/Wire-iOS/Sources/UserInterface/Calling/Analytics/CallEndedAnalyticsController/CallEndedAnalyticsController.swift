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
    private var callStateObserverToken: AnyObject!

    init(contextProvider: ContextProvider) {
        self.contextProvider = contextProvider

        callStateObserverToken = WireCallCenterV3.addCallStateObserver(
            observer: self,
            contextProvider: contextProvider
        )
    }
}

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
            print("wexflwjdksf TODO: start analytics tracking")
        case .terminating(let reason):
            print("wexflwjdksf TODO: send analytics event and reset")
        default:
            break
        }
    }

}
