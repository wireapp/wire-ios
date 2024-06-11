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

    public static func == (lhs: UserCredentials, rhs: UserCredentials) -> Bool {
        let emailsEqual = lhs.email == rhs.email
        let passwordsEqual = lhs.password == rhs.password
        let phoneNumbersEqual = lhs.phoneNumber == rhs.phoneNumber
        let phoneNumberCodesEqual = lhs.phoneNumberVerificationCode == rhs.phoneNumberVerificationCode
        let emailVerificationCodesEqual = lhs.emailVerificationCode == rhs.emailVerificationCode
        return emailsEqual && passwordsEqual && phoneNumbersEqual && phoneNumberCodesEqual && emailVerificationCodesEqual
    }

    @objc
    public var credentialWithEmail: Bool {
        return email != nil
    }

    @objc
    public var credentialWithPhone: Bool {
        return phoneNumber != nil
    }
}

@objcMembers
public class UserPhoneCredentials: UserCredentials {
    @objc(credentialsWithPhoneNumber:verificationCode:)
    public static func credentials(phoneNumber: String, verificationCode: String) -> UserPhoneCredentials {
        let validatedPhoneNumber = ZMPhoneNumberValidator.validatePhoneNumber(phoneNumber)
        return UserPhoneCredentials(phoneNumber: validatedPhoneNumber, phoneNumberVerificationCode: verificationCode)
    }
}

@objcMembers
public class UserEmailCredentials: UserCredentials {
    @objc(credentialsWithEmail:password:)
    public static func credentials(email: String, password: String) -> UserEmailCredentials {
        return UserEmailCredentials(email: email, password: password, emailVerificationCode: nil)
    }

    @objc(credentialsWithEmail:password:emailVerificationCode:)
    public static func credentials(email: String, password: String, emailVerificationCode: String?) -> UserEmailCredentials {
        return UserEmailCredentials(email: email, password: password, emailVerificationCode: emailVerificationCode)
    }

    @objc(testForAgisWithEmail:password:)
    public static func testForAgis(email: String, password: String) -> UserEmailCredentials {
        return UserEmailCredentials(email: email, password: password, emailVerificationCode: nil)
    }
}

// Assuming ZMPhoneNumberValidator exists and has a method validatePhoneNumber(_:)
class ZMPhoneNumberValidator {
    static func validatePhoneNumber(_ phoneNumber: String) -> String {
        // Add your phone number validation logic here
        return phoneNumber
    }
}
