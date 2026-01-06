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

import Foundation

public extension ZMConversation {

    // TODO: [WPB-18396] implement NSManagedObject local property and map it to return proper duration value

    var channelHistoryDepth: String? {
        get {
            nil
        }

        set {}
    }

    // TODO: [WPB-18470] Encrypted history messages will be stored in DB - return true if array has encrypted messages, false if empty (meaning all history messages have been decrypted and shown to the user)

    var hasMoreHistory: Bool {
        true
    }

}
