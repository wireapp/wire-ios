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

@MainActor
final class KMPViewModelEnvironmentTests: XCTestCase {

    func testLegacyOnlyEnvironmentKeepsSessionInLegacyMode() {
        // GIVEN
        let context = SessionBoundaryContext(accountID: "account-1", sessionID: "session-1")

        // WHEN
        let sut = KMPViewModelEnvironment.legacyOnly(sessionBoundaryContext: context)

        // THEN
        XCTAssertEqual(sut.sessionBoundaryContext, context)
        XCTAssertEqual(sut.sessionBoundaryMode, .legacyOnly)
    }

    func testEnvironmentCanResolveModeForSessionContext() {
        // GIVEN
        let expectedContext = SessionBoundaryContext(accountID: "account-1", sessionID: "session-1")
        let sut = KMPViewModelEnvironment(
            sessionBoundaryContext: expectedContext,
            sessionBoundaryModeResolver: SessionBoundaryModeResolverFactory.makeResolver { context in
                XCTAssertEqual(context, expectedContext)
                return .kaliumPrepared
            },
            viewModelFactory: DefaultKMPViewModelFactory()
        )

        // WHEN / THEN
        XCTAssertEqual(sut.sessionBoundaryMode, .kaliumPrepared)
    }

    func testEnvironmentBuildsViewModelsThroughFactory() {
        // GIVEN
        let source = FakeKMPViewModelSource<TestState, TestEffect, TestIntent>(initialState: .idle)
        let sut = KMPViewModelEnvironment.legacyOnly(
            sessionBoundaryContext: SessionBoundaryContext(accountID: "account-1")
        )

        // WHEN
        let viewModel = sut.makeViewModel(for: source.makeDescriptor())
        source.publish(state: .loaded)
        viewModel.send(.refresh)

        // THEN
        XCTAssertEqual(viewModel.state, .loaded)
        source.assertSentIntents([.refresh])
    }

    func testScreenGateKeepsLegacyScreensInLegacyMode() {
        // GIVEN
        let sut = KMPViewModelEnvironment.legacyOnly(
            sessionBoundaryContext: SessionBoundaryContext(accountID: "account-1")
        )

        for screenID in knownScreenIDs {
            // WHEN
            let usesKMPViewModel = sut.usesKMPViewModel(
                for: screenID,
                isKMPImplementationAvailable: true
            )

            // THEN
            XCTAssertFalse(usesKMPViewModel, "Expected legacy mode for \(screenID)")
        }
    }

    func testScreenGateRequiresEnabledSessionAndAvailableKMPImplementation() {
        // GIVEN
        let context = SessionBoundaryContext(accountID: "account-1")
        let sut = KMPViewModelEnvironment(
            sessionBoundaryContext: context,
            sessionBoundaryModeResolver: SessionBoundaryModeResolverFactory.makeResolver { _ in .kaliumEnabled },
            viewModelFactory: DefaultKMPViewModelFactory()
        )

        // WHEN / THEN
        for screenID in knownScreenIDs {
            XCTAssertFalse(
                sut.usesKMPViewModel(
                    for: screenID,
                    isKMPImplementationAvailable: false
                ),
                "Expected unavailable KMP implementation to keep legacy for \(screenID)"
            )

            XCTAssertTrue(
                sut.usesKMPViewModel(
                    for: screenID,
                    isKMPImplementationAvailable: true
                ),
                "Expected enabled KMP implementation for \(screenID)"
            )
        }
    }
}

// MARK: - Test Types

private let knownScreenIDs: [KMPViewModelScreenID] = [
    .archivedList,
    .createGroupConversation,
    .folderPicker,
    .selfProfile
]

private enum TestState: Equatable {
    case idle
    case loaded
}

private enum TestEffect: Equatable {
    case none
}

private enum TestIntent: Equatable {
    case refresh
}
