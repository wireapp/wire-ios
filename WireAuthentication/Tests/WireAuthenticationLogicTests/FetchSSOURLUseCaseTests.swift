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

import WireAPI
import WireAPISupport
import WireAuthenticationAPI
import WireAuthenticationAPISupport
import WireTestingPackage
import XCTest

@testable import WireAuthenticationLogic

final class FetchSSOURLUseCaseTests: XCTestCase {

    private var authenticationAPI: MockAuthenticationAPI!
    private var linkGenerator: MockSSOLinkGeneratorProtocol!
    private var sut: FetchSSOURLUseCase!

    override func setUp() {
        authenticationAPI = MockAuthenticationAPI()
        linkGenerator = MockSSOLinkGeneratorProtocol()
        sut = FetchSSOURLUseCase(
            authenticationAPI: authenticationAPI,
            linkGenerator: linkGenerator
        )
    }

    override func tearDown() {
        authenticationAPI = nil
        linkGenerator = nil
        sut = nil
    }

    func testInvoke_whenSuccess() async throws {
        // given
        let ssoCode = UUID()

        // mock
        authenticationAPI.getSSOCode_MockValue = ssoCode
        linkGenerator.generateSSOLinkSsoCode_MockValue = URL(string: "www.wire.com/ssoURL/\(ssoCode.uuidString)")!

        // when
        let ssoURL = try await sut.invoke()

        // then
        XCTAssertEqual(ssoURL, URL(string: "www.wire.com/ssoURL/\(ssoCode.uuidString)"))
    }

    func testInvoke_whenFailure() async throws {
        // given
        authenticationAPI.getSSOCode_MockError = URLError(.badURL)

        // when, then it forwards the error
        await XCTAssertThrowsErrorAsync(URLError(.badURL)) { [self] in
            _ = try await sut.invoke()
        }
    }

}
