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

final class SessionBoundaryModeResolverTests: XCTestCase {

    func testDefaultFactoryReturnsLegacyOnlyMode() {
        // GIVEN
        let sut = SessionBoundaryModeResolverFactory.makeDefaultResolver()
        let context = SessionBoundaryContext(
            accountID: "account-1",
            sessionID: "session-1"
        )

        // WHEN
        let mode = sut.mode(for: context)

        // THEN
        XCTAssertEqual(mode, .legacyOnly)
    }

    func testResolverCanSelectModePerContext() {
        // GIVEN
        let sut = SessionBoundaryModeResolverFactory.makeResolver { context in
            switch context.accountID {
            case "kalium-prepared":
                return .kaliumPrepared
            case "kalium-enabled":
                return .kaliumEnabled
            default:
                return .legacyOnly
            }
        }

        // WHEN / THEN
        XCTAssertEqual(
            sut.mode(for: SessionBoundaryContext(accountID: "legacy", sessionID: "session-1")),
            .legacyOnly
        )
        XCTAssertEqual(
            sut.mode(for: SessionBoundaryContext(accountID: "kalium-prepared", sessionID: "session-2")),
            .kaliumPrepared
        )
        XCTAssertEqual(
            sut.mode(for: SessionBoundaryContext(accountID: "kalium-enabled", sessionID: "session-3")),
            .kaliumEnabled
        )
    }

    func testModeCapabilitiesSeparatePreparationFromViewModelUsage() {
        XCTAssertFalse(SessionBoundaryMode.legacyOnly.preparesKaliumSession)
        XCTAssertFalse(SessionBoundaryMode.legacyOnly.usesKaliumViewModels)

        XCTAssertTrue(SessionBoundaryMode.kaliumPrepared.preparesKaliumSession)
        XCTAssertFalse(SessionBoundaryMode.kaliumPrepared.usesKaliumViewModels)

        XCTAssertTrue(SessionBoundaryMode.kaliumEnabled.preparesKaliumSession)
        XCTAssertTrue(SessionBoundaryMode.kaliumEnabled.usesKaliumViewModels)
    }
}
