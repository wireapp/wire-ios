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

import WireFoundation

/// The representation of a user that is going through the registration process.
///
/// Typically, you create this object once you start the registration flow and start asking
/// for credentails and metadata. You set the values to the properties of this class
/// as the user provides them to the app.
///
/// You then use it to register the user with the backend.
public class UnregisteredUser {

    public var unverifiedEmail = ""
    public var verificationCode: String?
    public var name: String?
    public var accentColorValue: ZMAccentColorRawValue?
    public var acceptedTermsOfService: Bool?
    public var marketingConsent: Bool?
    public var password: String?

    public var accentColor: AccentColor? {
        get {
            guard let accentColorValue else { return nil }
            return .init(rawValue: accentColorValue)
        }
        set {
            accentColorValue = newValue?.rawValue
        }
    }

    /**
     * Creates an empty unregistered user.
     */

    public init() {}

    /// Whether the user is complete and can be registered.
    public var isComplete: Bool {
        let passwordStepFinished = needsPassword ? password != nil : true

        return !unverifiedEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && verificationCode != nil
            && name != nil
            && accentColor != nil
            && acceptedTermsOfService != nil
            && marketingConsent != nil
            && passwordStepFinished
    }

    /// Whether the user needs a password.
    public var needsPassword: Bool {
        password == nil
    }

}

// MARK: - Equatable

extension UnregisteredUser: Equatable {

    public static func == (lhs: UnregisteredUser, rhs: UnregisteredUser) -> Bool {
        return lhs.unverifiedEmail == rhs.unverifiedEmail
            && lhs.verificationCode == rhs.verificationCode
            && lhs.name == rhs.name
            && lhs.accentColor == rhs.accentColor
            && lhs.acceptedTermsOfService == rhs.acceptedTermsOfService
            && lhs.marketingConsent == rhs.marketingConsent
            && lhs.password == rhs.password
    }

}
