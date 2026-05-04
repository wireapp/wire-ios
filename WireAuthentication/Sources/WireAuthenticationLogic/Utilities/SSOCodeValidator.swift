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

enum SSOCodeValidator {

    /// Returns an SSO `UUID` if `ssoCode` is a valid SSO code otherwise `nil`.
    ///
    /// A valid SSO code is a UUID prefixed by `wire-`.

    static func validate(ssoCode: String) -> UUID? {
        let code = ssoCode.lowercased()
        let prefix = "wire-"

        guard code.hasPrefix(prefix) else { return nil }
        return UUID(uuidString: String(code.dropFirst(prefix.count)))
    }
}
