//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

@testable import Wire
import WireSyncEngine

struct CallStateMock: CallStateExtending {
    var isConnected: Bool
    var isTerminating: Bool
    var canAccept: Bool
}

extension CallStateMock {
    static var incoming: CallStateMock {
        return CallStateMock(isConnected: false, isTerminating: false, canAccept: true)
    }

    static var outgoing: CallStateMock {
        return CallStateMock(isConnected: false, isTerminating: false, canAccept: false)
    }

    static var terminating: CallStateMock {
        return CallStateMock(isConnected: false, isTerminating: true, canAccept: false)
    }

    static var ongoing: CallStateMock {
        return CallStateMock(isConnected: true, isTerminating: false, canAccept: false)
    }
}
