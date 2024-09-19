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

/// Helper to conveniently use the `NSSecureCoding` method
/// `decodeObjectOfClass:forKey:` with `String` and `Data` without casting.
extension NSCoder {

    func decodeString(forKey key: String) -> String? {
        return decodeObject(of: NSString.self, forKey: key) as String?
    }

    func decodeData(forKey key: String) -> Data? {
        return decodeObject(of: NSData.self, forKey: key) as Data?
    }

}
