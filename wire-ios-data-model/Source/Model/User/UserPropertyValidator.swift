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

public struct UserPropertyValidator: UserPropertyValidating {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    // Name

    public func validate(name: inout String?) throws -> Bool {
        var mutableName: Any? = name

        try ExtremeCombiningCharactersValidator.validateCharactersValue(&mutableName)

        // The backend limits to 128. We'll fly just a bit below the radar.
        let validate = try StringLengthValidator.validateStringValue(
            &mutableName,
            minimumStringLength: 2,
            maximumStringLength: 100,
            maximumByteLength: UInt32.max
        )

        name = mutableName as? String

        return name == nil || validate
    }

    // E-mail address

    public func validate(emailAddress: inout String?) throws -> Bool {
        var mutableEmailAddress: Any? = emailAddress
        let result = try ZMEmailAddressValidator.validateValue(&mutableEmailAddress)
        emailAddress = mutableEmailAddress as? String
        return result
    }

    // Password

    public func validate(password: inout String?) throws -> Bool {
        var mutablePassword: Any? = password
        let result = try StringLengthValidator.validateStringValue(
            &mutablePassword,
            minimumStringLength: 8,
            maximumStringLength: 120,
            maximumByteLength: UInt32.max
        )
        password = mutablePassword as? String
        return result
    }

    // Phone number

    public func validate(phoneNumber: inout String?) throws -> Bool {
        guard var mutableNumber: Any? = phoneNumber,
              phoneNumber?.count ?? 0 >= 1 else {
            return false
        }

        let result = try ZMPhoneNumberValidator.validateValue(&mutableNumber)
        phoneNumber = mutableNumber as? String
        return result
    }

    // Verification code

    public func validate(phoneVerificationCode: inout String?) throws -> Bool {
        var mutableCode: Any? = phoneVerificationCode
        let result = try StringLengthValidator.validateStringValue(
            &mutableCode,
            minimumStringLength: 6,
            maximumStringLength: 6,
            maximumByteLength: UInt32.max
        )
        phoneVerificationCode = mutableCode as? String
        return result
    }
}
