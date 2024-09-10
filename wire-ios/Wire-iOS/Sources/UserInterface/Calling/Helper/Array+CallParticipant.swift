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
import WireSyncEngine

extension Array<CallParticipant> {
    var hasMoreThanTwoConnectedParticipants: Bool {
        filter(\.state.isConnected).count > 2
    }

    mutating func sortByName(selfStreamId: AVSClient?) {
        sort {
            if $0.streamId == selfStreamId {
                return true
            }

            return OptionalComparison.prependingNilAscending(
                lhs: $0.user.name?.lowercased(),
                rhs: $1.user.name?.lowercased()
            )
        }
    }
}
