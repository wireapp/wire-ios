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

public enum CallClosedReason: Int32, Sendable {
    case normal
    case canceled
    case answeredElsewhere
    case rejectedElsewhere
    case timeout
    case lostMedia
    case internalError
    case inputOutputError
    case stillOngoing
    case securityDegraded
    case outdatedClient
    case datachannel
    case timeoutECONN
    case noOneJoined
    case everyoneLeft
    case unknown

    init(wcall_reason: Int32) {
        switch wcall_reason {
        case WCALL_REASON_NORMAL:            self = .normal
        case WCALL_REASON_CANCELED:          self = .canceled
        case WCALL_REASON_ANSWERED_ELSEWHERE: self = .answeredElsewhere
        case WCALL_REASON_REJECTED:          self = .rejectedElsewhere
        case WCALL_REASON_TIMEOUT:           self = .timeout
        case WCALL_REASON_LOST_MEDIA:        self = .lostMedia
        case WCALL_REASON_ERROR:             self = .internalError
        case WCALL_REASON_IO_ERROR:          self = .inputOutputError
        case WCALL_REASON_STILL_ONGOING:     self = .stillOngoing
        case WCALL_REASON_OUTDATED_CLIENT:   self = .outdatedClient
        case WCALL_REASON_TIMEOUT_ECONN:     self = .timeoutECONN
        case WCALL_REASON_DATACHANNEL:       self = .datachannel
        case WCALL_REASON_NOONE_JOINED:      self = .noOneJoined
        case WCALL_REASON_EVERYONE_LEFT:     self = .everyoneLeft
        default:                             self = .unknown
        }
    }
}
