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

import Foundation

class CallObserver: WireCallCenterCallStateObserver {
    // MARK: Public

    public var onIncoming: VoidHandler?
    public var onAnswered: VoidHandler?
    public var onEstablished: VoidHandler?
    public var onFailedToJoin: VoidHandler?
    public var onTerminated: Handler<CallClosedReason>?

    public func startObservingChanges(in conversation: ZMConversation) {
        token = WireCallCenterV3.addCallStateObserver(
            observer: self,
            for: conversation,
            context: conversation.managedObjectContext!
        )
    }

    public func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        switch callState {
        case .incoming:
            onIncoming?()

        case .answered(degraded: false):
            onAnswered?()

        case .established, .establishedDataChannel:
            onEstablished?()

        case let .terminating(reason: reason):
            switch reason {
            case .answeredElsewhere, .inputOutputError, .internalError, .lostMedia, .unknown:
                onFailedToJoin?()

            default:
                onTerminated?(reason)
            }

        default:
            break
        }
    }

    // MARK: Internal

    typealias VoidHandler = () -> Void
    typealias Handler<T> = (T) -> Void

    // MARK: Private

    private var token: Any?
}
