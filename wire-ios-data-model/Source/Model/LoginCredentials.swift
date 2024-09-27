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

/// Contains the credentials used by a user to sign into the app.

@objc
public class LoginCredentials: NSObject, Codable {
    // MARK: Lifecycle

    public init(emailAddress: String?, hasPassword: Bool, usesCompanyLogin: Bool) {
        self.emailAddress = emailAddress
        self.hasPassword = hasPassword
        self.usesCompanyLogin = usesCompanyLogin
    }

    // MARK: Public

    @objc public let emailAddress: String?
    @objc public let hasPassword: Bool
    @objc public let usesCompanyLogin: Bool

    override public var debugDescription: String {
        "<LoginCredentials>:\n\temailAddress: \(String(describing: emailAddress))\n\thasPassword: \(hasPassword)\n\tusesCompanyLogin: \(usesCompanyLogin)"
    }

    override public var hash: Int {
        var hasher = Hasher()
        hasher.combine(emailAddress)
        hasher.combine(hasPassword)
        hasher.combine(usesCompanyLogin)
        return hasher.finalize()
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let otherCredentials = object as? LoginCredentials else {
            return false
        }

        let emailEquals = emailAddress == otherCredentials.emailAddress
        let passwordEquals = hasPassword == otherCredentials.hasPassword
        let companyLoginEquals = usesCompanyLogin == otherCredentials.usesCompanyLogin

        return emailEquals && passwordEquals && companyLoginEquals
    }
}
