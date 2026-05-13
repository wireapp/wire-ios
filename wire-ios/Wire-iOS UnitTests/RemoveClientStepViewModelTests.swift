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

final class RemoveClientStepViewModelTests: XCTestCase {

    private var sut: RemoveClientStepViewModel!

    override func setUp() {
        super.setUp()
        sut = RemoveClientStepViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testDisplayStateWhenCanCancel() {
        XCTAssertEqual(
            sut.displayState(canCancel: true),
            RemoveClientStepViewModel.DisplayState(
                navigationTitle: L10n.Localizable.Registration.Signin.TooManyDevices.ManageScreen.title,
                regularContentWidth: 375,
                showsCancelButton: true,
                isCancelButtonEnabled: true
            )
        )
    }

    func testDisplayStateWhenCannotCancel() {
        XCTAssertEqual(
            sut.displayState(canCancel: false),
            RemoveClientStepViewModel.DisplayState(
                navigationTitle: L10n.Localizable.Registration.Signin.TooManyDevices.ManageScreen.title,
                regularContentWidth: 375,
                showsCancelButton: false,
                isCancelButtonEnabled: false
            )
        )
    }

    func testCancelTappedRoutesToCancel() {
        XCTAssertEqual(sut.routeForCancelTapped(), .cancel)
    }

    func testFinishedDeletingContinuesFlow() {
        guard case .continueAfterRemovingClient = sut.actionForFinishedDeleting() else {
            return XCTFail("Expected continueAfterRemovingClient action")
        }
    }

    func testFailedToDeleteClientsShowsRemovalError() {
        let expectedError = NSError(domain: "RemoveClientStepViewModelTests", code: 1)

        guard case let .showRemovalError(error) = sut.actionForFailedToDeleteClients(expectedError) else {
            return XCTFail("Expected showRemovalError action")
        }

        XCTAssertEqual(error as NSError, expectedError)
    }
}
