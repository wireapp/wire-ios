//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
@testable import WireRequestStrategy

class SendMLSWelcomeActionHandlerTests: ActionHandlerTestBase<SendMLSWelcomeAction, SendMLSWelcomeActionHandler> {

    let welcomeMessage = "welcome!".data(using: .utf8)!

    override func setUp() {
        super.setUp()
        action = SendMLSWelcomeAction(welcomeMessage: welcomeMessage)
    }

    // MARK: - Request generation

    func test_itGenerateARequest() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v1/mls/welcome",
            expectedMethod: .methodPOST,
            expectedData: welcomeMessage,
            expectedContentType: "message/mls",
            apiVersion: .v1
        )
    }

    func test_itDoesntGenerateRequests() {
        // when the endpoint is unavailable
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v0,
            expectedError: .endpointUnavailable
        )

        // when there are empty parameters
        test_itDoesntGenerateARequest(
            action: SendMLSWelcomeAction(welcomeMessage: Data()),
            apiVersion: .v1,
            expectedError: .emptyParameters
        )
    }

    // MARK: - Response handling

    func test_itHandlesSuccess() {
        test_itHandlesSuccess(status: 201)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 400, error: .invalidBody),
            .failure(status: 404, error: .keyPackageRefNotFound, label: "mls-key-package-ref-not-found"),
            .failure(status: 999, error: .unknown(status: 999))
        ])
    }
}
