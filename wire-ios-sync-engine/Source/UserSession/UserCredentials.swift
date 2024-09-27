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

// MARK: - UserCredentials

@objcMembers
public class UserCredentials: NSObject {
    public var email: String?
    public var password: String?
    public var phoneNumber: String?
    public var phoneNumberVerificationCode: String?
    public var emailVerificationCode: String?

    public init(
        email: String? = nil,
        password: String? = nil,
        phoneNumber: String? = nil,
        phoneNumberVerificationCode: String? = nil,
        emailVerificationCode: String? = nil
    ) {
        self.email = email
        self.password = password
        self.phoneNumber = phoneNumber
        self.phoneNumberVerificationCode = phoneNumberVerificationCode
        self.emailVerificationCode = emailVerificationCode
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UserCredentials else {
            return false
        }
        return email == other.email &&
            password == other.password &&
            phoneNumber == other.phoneNumber &&
            phoneNumberVerificationCode == other.phoneNumberVerificationCode &&
            emailVerificationCode == other.emailVerificationCode
    }

    override public var hash: Int {
        var hasher = Hasher()
        hasher.combine(email)
        hasher.combine(password)
        hasher.combine(phoneNumber)
        hasher.combine(phoneNumberVerificationCode)
        hasher.combine(emailVerificationCode)
        return hasher.finalize()
    }


    public var credentialWithEmail: Bool {
        email != nil
    }


    public var credentialWithPhone: Bool {
        phoneNumber != nil
    }
}

// MARK: - UserPhoneCredentials

@objcMembers
public class UserPhoneCredentials: UserCredentials {
    @objc(credentialsWithPhoneNumber:verificationCode:)
    public static func credentials(phoneNumber: String, verificationCode: String) -> UserPhoneCredentials {
        let validatedPhoneNumber = ZMPhoneNumberValidator.validate(phoneNumber: phoneNumber)
        return UserPhoneCredentials(phoneNumber: validatedPhoneNumber, phoneNumberVerificationCode: verificationCode)
    }
}

// MARK: - UserEmailCredentials

@objcMembers
public class UserEmailCredentials: UserCredentials {
    @objc(credentialsWithEmail:password:)
    public static func credentials(email: String, password: String) -> UserEmailCredentials {
        UserEmailCredentials(email: email, password: password, emailVerificationCode: nil)
    }

    @objc(credentialsWithEmail:password:emailVerificationCode:)
    public static func credentials(
        email: String,
        password: String,
        emailVerificationCode: String?
    ) -> UserEmailCredentials {
        UserEmailCredentials(email: email, password: password, emailVerificationCode: emailVerificationCode)
    }
}
