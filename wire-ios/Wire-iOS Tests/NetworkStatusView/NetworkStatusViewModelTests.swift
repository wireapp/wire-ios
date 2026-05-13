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

final class NetworkStatusViewModelTests: XCTestCase {

    func testViewStateMappingFromNetworkState() {
        // GIVEN
        let sut = NetworkStatusViewModel()

        // THEN
        XCTAssertEqual(sut.viewState(from: .offline), .offlineExpanded)
        XCTAssertEqual(sut.viewState(from: .online), .online)
        XCTAssertEqual(sut.viewState(from: .onlineSynchronizing), .onlineSynchronizing)
    }

    func testApplyPendingStatePromotesPendingToCurrentAndClearsPending() {
        // GIVEN
        let sut = NetworkStatusViewModel()
        sut.enqueue(state: .offlineExpanded)

        // WHEN
        let appliedState = sut.applyPendingState()

        // THEN
        XCTAssertEqual(appliedState, .offlineExpanded)
        XCTAssertEqual(sut.currentState, .offlineExpanded)
        XCTAssertNil(sut.pendingState)
    }

    func testApplicationActiveStatePrefersPendingState() {
        // GIVEN
        let sut = NetworkStatusViewModel()
        sut.update(state: .onlineSynchronizing)
        sut.enqueue(state: .offlineExpanded)

        // WHEN
        let state = sut.stateToEnqueueWhenApplicationBecomesActive()

        // THEN
        XCTAssertEqual(state, .offlineExpanded)
    }

    func testRouteForTapReturnsOfflineAlertOnlyForExpandedOfflineState() {
        // GIVEN
        let sut = NetworkStatusViewModel()

        // THEN
        XCTAssertEqual(
            sut.routeForTap(on: .offlineExpanded),
            .offlineAlert(
                .init(
                    title: NetworkStatusViewModel.Localizable.title,
                    message: NetworkStatusViewModel.Localizable.explanation
                )
            )
        )
        XCTAssertEqual(sut.routeForTap(on: .online), .none)
        XCTAssertEqual(sut.routeForTap(on: .onlineSynchronizing), .none)
    }

    func testIPadVisibilityDecisionHidesRegularSizeClassWhenDelegateDisallowsDisplay() {
        // GIVEN
        let sut = NetworkStatusViewModel()
        sut.update(state: .offlineExpanded)

        // WHEN
        let visibleState = sut.visibleStateForIPadTraitChange(
            horizontalSizeClass: .regular,
            delegateAllowsDisplay: false
        )

        // THEN
        XCTAssertEqual(visibleState, .online)
    }

    func testIPadVisibilityDecisionKeepsCurrentStateForCompactSizeClass() {
        // GIVEN
        let sut = NetworkStatusViewModel()
        sut.update(state: .offlineExpanded)

        // WHEN
        let visibleState = sut.visibleStateForIPadTraitChange(
            horizontalSizeClass: .compact,
            delegateAllowsDisplay: false
        )

        // THEN
        XCTAssertEqual(visibleState, .offlineExpanded)
    }
}
