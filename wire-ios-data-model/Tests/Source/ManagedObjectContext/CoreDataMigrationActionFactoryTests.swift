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
    let excludedVersions: [CoreDataMessagingMigrationVersion] = [.version2_111, .version2_107]

    func test_ItReturnsPreActionForVersion211() {
        let action = CoreDataMigrationActionFactory.createPreMigrationAction(for: .version2_111)

        XCTAssertNotNil(action)
    }

    func test_ItReturnsPostActionForVersion211() {
        let action = CoreDataMigrationActionFactory.createPostMigrationAction(for: .version2_111)

        XCTAssertNotNil(action)
    }

    func test_ItReturnsPreActionForVersion207() {
        let action = CoreDataMigrationActionFactory.createPreMigrationAction(for: .version2_107)

        XCTAssertNotNil(action)
    }

    func test_ItReturnsNoPostActionForVersion207() {
        let action = CoreDataMigrationActionFactory.createPostMigrationAction(for: .version2_107)

        XCTAssertNil(action)
    }

    func test_ItReturnsNoPostActionForAllOtherVersions() {

        CoreDataMessagingMigrationVersion.allCases.filter({ !excludedVersions.contains($0) }).forEach {

            let action = CoreDataMigrationActionFactory.createPostMigrationAction(for: $0)
            XCTAssertNil(action)
        }
    }

    func test_ItReturnsNoPreActionForAllOtherVersions() {

        CoreDataMessagingMigrationVersion.allCases.filter({ !excludedVersions.contains($0) }).forEach {

            let action = CoreDataMigrationActionFactory.createPreMigrationAction(for: $0)
            XCTAssertNil(action)
        }
    }

}
