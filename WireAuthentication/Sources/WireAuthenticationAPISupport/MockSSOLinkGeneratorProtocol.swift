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

public final class MockSSOLinkGeneratorProtocol: @unchecked Sendable, SSOLinkGeneratorProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - generateSSOLink

    public var generateSSOLinkSSOCode_Invocations: [UUID] = []
    public var generateSSOLinkSSOCode_MockError: (any Error)?
    public var generateSSOLinkSSOCode_MockValue: URL?

    public func generateSSOLink(ssoCode: UUID) async throws -> URL {
        generateSSOLinkSSOCode_Invocations.append(ssoCode)

        if let error = generateSSOLinkSSOCode_MockError {
            throw error
        }

        guard let mock = generateSSOLinkSSOCode_MockValue else {
            fatalError("no mock for `generateSSOLinkSSOCode")
        }

        return mock
    }

    // MARK: - flushToken

    public var flushToken_InvocationCount = 0

    public func flushToken() {
        flushToken_InvocationCount += 1
    }

}
