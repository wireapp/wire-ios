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

public protocol UserDefaultsProtocol {
    /// User ID should be set beforehand
    static var userID: UUID! { get set }

}

public extension UserDefaultsProtocol {
    static func setup(
        userID: UUID
    ) {
        Self.userID = userID
    }
}

public extension UserDefaults {
    static func removeAll(
        forUserID userID: UUID,
        in storage: UserDefaults
    ) {
        let prefix = "\(userID.uuidString)_"
        let matchingKeys = storage.dictionaryRepresentation().keys.filter {
            $0.hasPrefix(prefix)
        }

        matchingKeys.forEach(storage.removeObject(forKey:))
    }
}
