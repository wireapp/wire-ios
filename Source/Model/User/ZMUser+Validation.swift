//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

public extension ZMUser {
    
    override func validateValue(_ value: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKey key: String) throws {
        if isInserted {
            return
        }
        
        try super.validateValue(value, forKey: key)
    }
    
    // Name
    
    static func isValidName(_ name: String?) -> Bool {
        var name = name
        do {
            return try validate(name: &name)
        } catch {
            return false
        }
    }
    
    static func validate(name: inout String?) throws -> Bool {
        
        var mutableName: Any? = name
        
        try ExtremeCombiningCharactersValidator.validateCharactersValue(&mutableName)
        
        // The backend limits to 128. We'll fly just a bit below the radar.
        let validate = try StringLengthValidator.validateStringValue(&mutableName, minimumStringLength: 2, maximumStringLength: 100, maximumByteLength: UInt32.max)
        
        name = mutableName as? String
        
        return name == nil || validate
    }
    
    @objc
    func validateName(_ value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        try ExtremeCombiningCharactersValidator.validateValue(value)
        
        do {
            try StringLengthValidator.validateValue(value, minimumStringLength: 2, maximumStringLength: 100, maximumByteLength: UInt32.max)
        } catch {
            if value.pointee == nil {
                return
            } else {
                throw error
            }
        }
    }
    
    // Accent color
    
    static func validate(accentColor: inout Int?) throws -> Bool {
        var mutableAccentColor: Any? = accentColor
        let result = try ZMAccentColorValidator.validateValue(&mutableAccentColor)
        accentColor = mutableAccentColor as? Int
        return result
    }
    
    @objc
    func validateAccentColorValue(_ value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        try ZMAccentColorValidator.validateValue(value)
    }
    
    // E-mail address
    
    static func isValidEmailAddress(_ emailAddress: String?) -> Bool {
        var emailAddress = emailAddress
        do {
            return try validate(emailAddress: &emailAddress)
        } catch {
            return false
        }
    }
    
    static func validate(emailAddress: inout String?) throws -> Bool {
        var mutableEmailAddress: Any? = emailAddress
        let result = try ZMEmailAddressValidator.validateValue(&mutableEmailAddress)
        emailAddress = mutableEmailAddress as? String
        return result

    }
    
    @objc
    func validateEmailAddress(_ value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        try ZMEmailAddressValidator.validateValue(value)
    }
    
    // Password
    
    static func isValidPassword(_ password: String?) -> Bool {
        var password = password
        do {
            return try validate(password: &password)
        } catch {
            return false
        }
    }
    
    static func validate(password: inout String?) throws -> Bool {
        var mutablePassword: Any? = password
        let result = try StringLengthValidator.validateStringValue(&mutablePassword,
                                                                 minimumStringLength: 8,
                                                                 maximumStringLength: 120,
                                                                 maximumByteLength: UInt32.max)
        password = mutablePassword as? String
        return result
    }
    
    // Phone number
    
    static func isValidPhoneNumber(_ phoneNumber: String?) -> Bool {
        var phoneNumber = phoneNumber
        do {
            return try validate(phoneNumber: &phoneNumber)
        } catch {
            return false
        }
    }
    
    static func validate(phoneNumber: inout String?) throws -> Bool {
        guard var mutableNumber: Any? = phoneNumber,
            phoneNumber?.count ?? 0 >= 1 else {
                return false
        }
        
        let result = try ZMPhoneNumberValidator.validateValue(&mutableNumber)
        phoneNumber = mutableNumber as? String
        return result
    }
    
    // Verification code
    
    static func isValidPhoneVerificationCode(_ phoneVerificationCode: String?) -> Bool {
        var phoneVerificationCode = phoneVerificationCode
        do {
            return try validate(phoneVerificationCode: &phoneVerificationCode)
        } catch {
            return false
        }
    }
    
    static func validate(phoneVerificationCode: inout String?) throws -> Bool {
        var mutableCode: Any? = phoneVerificationCode
        let result = try StringLengthValidator.validateStringValue(&mutableCode, minimumStringLength: 6, maximumStringLength: 6, maximumByteLength: UInt32.max)
        phoneVerificationCode = mutableCode as? String
        return result
    }
}

