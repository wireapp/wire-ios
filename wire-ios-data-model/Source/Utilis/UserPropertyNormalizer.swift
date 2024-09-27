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

public struct UserPropertyNormalizer: UserPropertyNormalization {
    // MARK: Lifecycle

    public init(userPropertyValidator: UserPropertyValidating) {
        self.userPropertyValidator = userPropertyValidator
    }

    public init() {
        self.init(userPropertyValidator: UserPropertyValidator())
    }

    // MARK: Public

    public var userPropertyValidator: UserPropertyValidating

    public func normalizeName(_ name: String) -> UserPropertyNormalizationResult<String> {
        var name: String? = name
        var outError: Error?
        var result = false

        do {
            result = try userPropertyValidator.validate(name: &name)
        } catch {
            outError = error
        }

        return UserPropertyNormalizationResult<String>(
            isValid: result,
            normalizedValue: name as String? ?? "",
            validationError: outError
        )
    }

    public func normalizeEmailAddress(_ emailAddress: String) -> UserPropertyNormalizationResult<String> {
        var emailAddress: String? = emailAddress
        var outError: Error?
        var result = false

        do {
            result = try userPropertyValidator.validate(emailAddress: &emailAddress)
        } catch {
            outError = error
        }

        return UserPropertyNormalizationResult<String>(
            isValid: result,
            normalizedValue: emailAddress as String? ?? "",
            validationError: outError
        )
    }

    public func normalizePassword(_ password: String) -> UserPropertyNormalizationResult<String> {
        var password: String? = password
        var outError: Error?
        var result = false

        do {
            result = try userPropertyValidator.validate(password: &password)
        } catch {
            outError = error
        }

        return UserPropertyNormalizationResult<String>(
            isValid: result,
            normalizedValue: password as String? ?? "",
            validationError: outError
        )
    }

    public func normalizeVerificationCode(_ verificationCode: String) -> UserPropertyNormalizationResult<String> {
        var verificationCode: String? = verificationCode
        var outError: Error?
        var result = false

        do {
            result = try userPropertyValidator.validate(phoneVerificationCode: &verificationCode)
        } catch {
            outError = error
        }

        return UserPropertyNormalizationResult<String>(
            isValid: result,
            normalizedValue: verificationCode as String? ?? "",
            validationError: outError
        )
    }

    public func normalizePhoneNumber(_ phoneNumber: String) -> UserPropertyNormalizationResult<String> {
        var phoneNumber: String? = phoneNumber
        var outError: Error?
        var result = false

        do {
            result = try userPropertyValidator.validate(phoneNumber: &phoneNumber)
        } catch {
            outError = error
        }

        return UserPropertyNormalizationResult<String>(
            isValid: result,
            normalizedValue: phoneNumber as String? ?? "",
            validationError: outError
        )
    }
}
