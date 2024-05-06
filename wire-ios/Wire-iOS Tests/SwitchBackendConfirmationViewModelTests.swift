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

@testable import Wire
import XCTest

final class SwitchBackendConfirmationViewModelTests: XCTestCase {

    private func createSUT(didConfirm: @escaping (Bool) -> Void) -> SwitchBackendConfirmationViewModel {
        SwitchBackendConfirmationViewModel(
            backendName: "www.backendName.com",
            backendURL: "www.backendURL.com",
            backendWSURL: "www.backendWSURL.com",
            blacklistURL: "www.blacklistURL.com",
            teamsURL: "www.teamsURL.com",
            accountsURL: "www.accountsURL.com",
            websiteURL: "www.websiteURL.com",
            didConfirm: didConfirm
        )
    }

    func testItConfirmsWhenUserDidConfirm() async throws {
        // Given
        let done = expectation(description: "done")
        var didConfirm = false

        let sut = createSUT {
            didConfirm = $0
            done.fulfill()
        }

        // When
        sut.handleEvent(.userDidConfirm)

        // Then
        await fulfillment(of: [done], timeout: 0.5)
        XCTAssertTrue(didConfirm)
    }

    func testItDoesNotConfirmWhenUserDidCancel() async throws {
        // Given
        let done = expectation(description: "done")
        var didConfirm = false

        let sut = createSUT {
            didConfirm = $0
            done.fulfill()
        }

        // When
        sut.handleEvent(.userDidCancel)

        // Then
        await fulfillment(of: [done], timeout: 0.5)
        XCTAssertFalse(didConfirm)
    }

}
