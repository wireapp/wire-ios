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

import XCTest

@testable import Wire
@testable import WireRequestStrategy

@MainActor
final class E2EIEnrollmentFlowTests: XCTestCase {

    private var oauthUseCase: MockOAuthUseCaseInterface!
    private var targetVC: UIViewController!
    private var window: UIWindow!

    override func setUp() {
        oauthUseCase = MockOAuthUseCaseInterface()
        targetVC = UIViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = targetVC
        window.isHidden = false
    }

    override func tearDown() {
        oauthUseCase = nil
        targetVC = nil
        window?.isHidden = true
        window = nil
    }

    // MARK: - OAuth integration

    func test_authenticate_callsOAuthUseCaseInvoke() async throws {
        // Given
        oauthUseCase.invokeParametersOnWebViewPresentingOnWebViewDismissed_MockValue = OAuthResponse(
            idToken: "id",
            refreshToken: "refresh"
        )
        let sut = makeSUT()

        // When
        _ = try await sut.authenticate(makeParameters())

        // Then
        XCTAssertEqual(oauthUseCase.invokeParametersOnWebViewPresentingOnWebViewDismissed_Invocations.count, 1)
    }

    func test_authenticate_returnsResponseFromUseCase() async throws {
        // Given
        let expectedResponse = OAuthResponse(idToken: "expected-id-token", refreshToken: "refresh")
        oauthUseCase.invokeParametersOnWebViewPresentingOnWebViewDismissed_MockValue = expectedResponse
        let sut = makeSUT()

        // When
        let result = try await sut.authenticate(makeParameters())

        // Then
        XCTAssertEqual(result.idToken, expectedResponse.idToken)
    }

    func test_authenticate_propagatesErrorFromUseCase() async {
        // Given
        oauthUseCase.invokeParametersOnWebViewPresentingOnWebViewDismissed_MockError = TestError.boom
        let sut = makeSUT()

        // When / Then
        do {
            _ = try await sut.authenticate(makeParameters())
            XCTFail("Expected error to be thrown")
        } catch TestError.boom {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> E2EIEnrollmentFlow {
        E2EIEnrollmentFlow(
            oauthUseCase: oauthUseCase,
            targetVC: { [unowned self] in targetVC }
        )
    }

    private func makeParameters() -> OAuthParameters {
        OAuthParameters(
            identityProvider: URL(string: "https://idp.example.com")!,
            clientID: "test-client",
            keyauth: "test-keyauth",
            acmeAudience: "test-audience"
        )
    }

    private enum TestError: Error {
        case boom
    }
}
