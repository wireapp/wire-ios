//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Testing
import WireAuthenticationAPI
import WireNetwork
import WireNetworkSupport

@testable import WireAuthenticationLogic

struct RequestLoginVerificationCodeUseCaseTests {

    @Test("UseCase passes the argument to the API")
    func passEmailArgumentToAPI() async throws {
        // Given
        let mockAuthenticationAPI = MockAuthenticationAPI()
        let sut = RequestLoginVerificationCodeUseCase(authenticationAPI: mockAuthenticationAPI)

        try await confirmation { confirmation in

            // Then
            mockAuthenticationAPI.requestVerificationCodeFor_MockMethod = { email in
                #expect(email == "email value")
                confirmation()
            }

            // When
            try await sut.invoke(email: "email value")
        }
    }

    @Test("UseCase maps invalid email error")
    func mapInvalidEmailError() async throws {
        // Given
        let mockAuthenticationAPI = MockAuthenticationAPI()
        mockAuthenticationAPI.requestVerificationCodeFor_MockError = AuthenticationAPIError.invalidEmail
        let sut = RequestLoginVerificationCodeUseCase(authenticationAPI: mockAuthenticationAPI)

        do {

            // When
            try await sut.invoke(email: "email value")
            Issue.record("Error isn't thrown")

        } catch RequestLoginVerificationCodeUseCaseFailure.invalidEmail {

            // Then
            // ok

        } catch {

            Issue.record("Unexpected error: " + String(reflecting: error))

        }
    }

    @Test("UseCase forwards any other error")
    func mapUnexpectedError() async throws {
        // Given
        let mockAuthenticationAPI = MockAuthenticationAPI()
        mockAuthenticationAPI.requestVerificationCodeFor_MockError = SomeError.some
        let sut = RequestLoginVerificationCodeUseCase(authenticationAPI: mockAuthenticationAPI)

        do {

            // When
            try await sut.invoke(email: "email value")
            Issue.record("Error isn't thrown")

        } catch {

            // Then
            #expect(error is SomeError)
        }
    }

}

private enum SomeError: Error {
    case some
}
