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

final class PreBackendSwitchViewModelTests: XCTestCase {

    func testItExposesDisplayState() {
        // Given
        let sut = PreBackendSwitchViewModel(
            title: "Switching backend",
            subtitle: "This takes a moment",
            information: "You will be redirected shortly",
            progressDuration: 10
        )

        // Then
        XCTAssertEqual(
            sut.state,
            PreBackendSwitchViewModel.State(
                title: "Switching backend",
                subtitle: "This takes a moment",
                information: "You will be redirected shortly",
                progressDuration: 10
            )
        )
    }

    func testItCompletesBackendSwitchWhenTimerCompletesWithBackendURL() async throws {
        // Given
        let done = expectation(description: "done")
        let backendURL = try XCTUnwrap(URL(string: "https://example.com"))
        var completedURL: URL?
        let sut = PreBackendSwitchViewModel(backendURL: backendURL) {
            completedURL = $0
            done.fulfill()
        }

        // When
        let route = sut.handleAction(.timerCompleted)
        sut.complete(route: route)

        // Then
        await fulfillment(of: [done], timeout: 1)
        XCTAssertEqual(sut.backendDecision(), .switchTo(backendURL))
        XCTAssertEqual(route, .complete(backendURL))
        XCTAssertEqual(completedURL, backendURL)
    }

    func testItDoesNotCompleteBackendSwitchWhenBackendURLIsMissing() {
        // Given
        var completedURL: URL?
        let sut = PreBackendSwitchViewModel {
            completedURL = $0
        }

        // When
        let route = sut.handleAction(.timerCompleted)
        sut.complete(route: route)

        // Then
        XCTAssertEqual(sut.backendDecision(), .unavailable)
        XCTAssertEqual(route, .none)
        XCTAssertNil(completedURL)
    }

}
