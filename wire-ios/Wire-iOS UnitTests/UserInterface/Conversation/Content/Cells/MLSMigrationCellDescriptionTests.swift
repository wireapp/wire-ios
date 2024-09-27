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

import XCTest
@testable import Wire

final class MLSMigrationCellDescriptionTests: XCTestCase {
    var otherUser: MockUserType!

    override func setUp() {
        super.setUp()
        otherUser = MockUserType.createUser(name: "Bruno")
    }

    override func tearDown() {
        otherUser = nil
        super.tearDown()
    }

    func testProperties() {
        // GIVEN
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationStarted)

        // WHEN && THEN
        XCTAssertEqual(cellDescription.topMargin, .zero)
        XCTAssertTrue(cellDescription.isFullWidth)
        XCTAssertFalse(cellDescription.supportsActions)
        XCTAssertFalse(cellDescription.showEphemeralTimer)
        XCTAssertFalse(cellDescription.containsHighlightableContent)
        XCTAssertNil(cellDescription.message)
        XCTAssertNil(cellDescription.delegate)
        XCTAssertNil(cellDescription.actionController)
        XCTAssertNotNil(cellDescription.configuration)
        XCTAssertNil(cellDescription.accessibilityIdentifier)
        XCTAssertEqual(cellDescription.accessibilityLabel?.isEmpty, false)
    }

    // MARK: - Attributed Strings

    func test_mlsMigrationStarted_doesContainLinkInAttributedString() throws {
        // GIVEN
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationStarted)
        var expectedValue: Any?

        // WHEN
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // THEN
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, _ in
            expectedValue = value
        })

        XCTAssertNotNil(expectedValue)
    }

    func test_mlsMigrationFinalized_doesContainLinkInAttributedString() throws {
        // GIVEN
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationFinalized)
        var expectedValue: Any?

        // WHEN
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // THEN
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, _ in
            expectedValue = value
        })

        XCTAssertNotNil(expectedValue)
    }

    func test_mlsMigrationOngoingCall_doesNotContainLinkInAttributedString() throws {
        // GIVEN
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationOngoingCall)
        var expectedValue: Any?

        // WHEN
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // THEN
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, _ in
            expectedValue = value
        })

        XCTAssertNil(expectedValue)
    }

    func test_mlsMigrationUpdateVersion_doesNotContainLinkInAttributedString() throws {
        // GIVEN
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationUpdateVersion)
        var expectedValue: Any?

        // WHEN
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // THEN
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, _ in
            expectedValue = value
        })

        XCTAssertNil(expectedValue)
    }

    func test_mlsMigrationJoinAfterwards_doesContainLinkInAttributedString() throws {
        // GIVEN
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationJoinAfterwards)
        var expectedValue: Any?

        // WHEN
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // THEN
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, _ in
            expectedValue = value
        })

        XCTAssertNotNil(expectedValue)
    }

    func test_mlsMigrationPotentialGap_doesContainLinkInAttributedString() throws {
        // GIVEN
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationPotentialGap)
        var expectedValue: Any?

        // WHEN
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // THEN
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, _ in
            expectedValue = value
        })

        XCTAssertNotNil(expectedValue)
    }
}
