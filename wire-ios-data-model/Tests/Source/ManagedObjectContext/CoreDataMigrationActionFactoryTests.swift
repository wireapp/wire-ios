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

@testable import WireDataModel
import XCTest

final class CoreDataMigrationActionFactoryTests: XCTestCase {

    // add version with actions here - aka custom migration
    let excludedVersions: [CoreDataMessagingMigrationVersion] = [
        .v116,
        .v114,
        .v111,
        .v107
    ]

    // MARK: - Version 116

    func test_ItReturnsPreActionForVersion116() {
        // given
        // when
        let action = CoreDataMigrationActionFactory.createPreMigrationAction(for: .v116)

        // then
        XCTAssertNil(action)
    }

    func test_ItReturnsPostActionForVersion116() {
        // given
        // when
        let action = CoreDataMigrationActionFactory.createPostMigrationAction(for: .v116)

        // then
        XCTAssertTrue(action is IsPendingInitialFetchMigrationAction)
    }

    // MARK: - Version 114

    func test_ItReturnsPreActionForVersion114() {
        // given
        // when
        let action = CoreDataMigrationActionFactory.createPreMigrationAction(for: .v114)

        // then
        XCTAssertNil(action)
    }

    func test_ItReturnsPostActionForVersion114() {
        // given
        // when
        let action = CoreDataMigrationActionFactory.createPostMigrationAction(for: .v114)

        // then
        XCTAssertTrue(action is OneOnOneConversationMigrationAction)
    }

    // MARK: - Version 111

    func test_ItReturnsPreActionForVersion111() {
        let action = CoreDataMigrationActionFactory.createPreMigrationAction(for: .v111)

        XCTAssertNotNil(action)
    }

    func test_ItReturnsPostActionForVersion2111() {
        let action = CoreDataMigrationActionFactory.createPostMigrationAction(for: .v111)

        XCTAssertNotNil(action)
    }

    // MARK: - Version 107

    func test_ItReturnsPreActionForVersion207() {
        let action = CoreDataMigrationActionFactory.createPreMigrationAction(for: .v107)

        XCTAssertNotNil(action)
    }

    func test_ItReturnsNoPostActionForVersion207() {
        let action = CoreDataMigrationActionFactory.createPostMigrationAction(for: .v107)

        XCTAssertNil(action)
    }

    // MARK: - Other Versions

    func test_ItReturnsNoPostActionForAllOtherVersions() {

        CoreDataMessagingMigrationVersion.allCases
            .filter { !excludedVersions.contains($0) }
            .forEach {
                let action = CoreDataMigrationActionFactory.createPostMigrationAction(for: $0)
                XCTAssertNil(action)
            }
    }

    func test_ItReturnsNoPreActionForAllOtherVersions() {

        CoreDataMessagingMigrationVersion.allCases
            .filter { !excludedVersions.contains($0) }
            .forEach {
                let action = CoreDataMigrationActionFactory.createPreMigrationAction(for: $0)
                XCTAssertNil(action)
            }
    }

}
