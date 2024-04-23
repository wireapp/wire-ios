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

/**
 * The representation of a user that is going through the registration process.
 *
 * Typically, you create this object once you start the registration flow and start asking
 * for credentails and metadata. You set the values to the properties of this class
 * as the user provides them to the app.
 *
 * You then use it to register the user with the backend.
 */

public class UnregisteredUser {

    public var credentials: UnverifiedCredentials?
    public var verificationCode: String?
    public var name: String?
    public var accentColorValue: AccentColor?
    public var acceptedTermsOfService: Bool?
    public var marketingConsent: Bool?
    public var password: String?

    /**
     * Creates an empty unregistered user.
     */

    public init() {}

    /// Whether the user is complete and can be registered.
    public var isComplete: Bool {
        let passwordStepFinished = needsPassword ? password != nil : true

        return credentials != nil
            && verificationCode != nil
            && name != nil
            && accentColorValue != nil
            && acceptedTermsOfService != nil
            && marketingConsent != nil
            && passwordStepFinished
    }

    /// Whether the user needs a password.
    public var needsPassword: Bool {
        switch credentials {
        case .phone?:
            return false
        default:
            return password == nil
        }
    }

}

// MARK: - Equatable

extension UnregisteredUser: Equatable {

    public static func == (lhs: UnregisteredUser, rhs: UnregisteredUser) -> Bool {
        return lhs.credentials == rhs.credentials
            && lhs.verificationCode == rhs.verificationCode
            && lhs.name == rhs.name
            && lhs.accentColorValue == rhs.accentColorValue
            && lhs.acceptedTermsOfService == rhs.acceptedTermsOfService
            && lhs.marketingConsent == rhs.marketingConsent
            && lhs.password == rhs.password
    }
}
