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

public enum UpdateEventsUserDefaults: UserDefaultsProtocol {
    public nonisolated(unsafe) static var userID: UUID!

    enum Key: String {
        case lastEventID
    }

    @UserDefault(key: Key.lastEventID, userID: userID)
    private static var _lastEventID: String?

    public static var lastEventID: UUID? {
        get {
            if let _lastEventID {
                return UUID(uuidString: _lastEventID)
            }

            return nil
        }
        set {
            _lastEventID = newValue?.uuidString
        }
    }
}
