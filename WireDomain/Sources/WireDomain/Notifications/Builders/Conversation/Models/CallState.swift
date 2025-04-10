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

enum CallState: Equatable {
    case incomingCall(video: Bool)
    case missedCall
    case unhandled

    init(callContent: CallContent) {
        let isStartCall = callContent.type.isOne(
            of: [
                CallType.setup,
                CallType.groupStart,
                CallType.confStart
            ]
        )
        let isIncomingCall = isStartCall && !callContent.responded
        let isEndCall = callContent.type.isOne(
            of: [
                CallType.cancel,
                CallType.groupEnd,
                CallType.confEnd
            ]
        )

        if isIncomingCall {
            self = .incomingCall(video: callContent.properties?.isVideo ?? false)
        } else if isEndCall {
            self = .missedCall
        } else {
            self = .unhandled
        }

    }
}
