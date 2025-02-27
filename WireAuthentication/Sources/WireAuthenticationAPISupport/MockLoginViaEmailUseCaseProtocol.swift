//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireAuthenticationAPI

public final class MockLoginViaEmailUseCaseProtocol: @unchecked Sendable, LoginViaEmailUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - invoke

    public var invokeEmailPasswordVerificationCode_Invocations: [
        (email: String, password: String, verificationCode: String?)
    ] = []
    public var invokeEmailPasswordVerificationCode_MockError: LoginViaEmailUseCaseFailure?
    public var invokeEmailPasswordVerificationCode_MockValue: ([HTTPCookie], AccessToken)?

    public func invoke(
        email: String,
        password: String,
        verificationCode: String?
    ) async throws(LoginViaEmailUseCaseFailure) -> ([HTTPCookie], AccessToken) {
        invokeEmailPasswordVerificationCode_Invocations.append(
            (email: email, password: password, verificationCode: verificationCode)
        )

        if let error = invokeEmailPasswordVerificationCode_MockError {
            throw error
        }

        guard let mock = invokeEmailPasswordVerificationCode_MockValue else {
            fatalError("no mock for `invokeEmailPasswordVerificationCode`")
        }

        return mock
    }

}
