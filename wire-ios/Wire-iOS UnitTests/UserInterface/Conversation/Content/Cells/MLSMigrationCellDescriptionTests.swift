//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import XCTest
import enum WireCommonComponents.FontScheme
@testable import Wire

final class MLSMigrationCellDescriptionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        FontScheme.configure(with: .large)
    }

    func testProperties() {
        // given
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationStarted)

        // when
        // then
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
        // given
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationStarted)
        let expectation = self.expectation(description: "")

        // when
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // then
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, processPtr in
            guard value != nil else { return }
            expectation.fulfill()
            processPtr.pointee = false
        })

        waitForExpectations(timeout: 0.1)
    }

    func test_mlsMigrationFinalized_doesContainLinkInAttributedString() throws {
        // given
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationFinalized)
        let expectation = self.expectation(description: "")

        // when
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // then
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, processPtr in
            guard value != nil else { return }
            expectation.fulfill()
            processPtr.pointee = false
        })

        waitForExpectations(timeout: 0.1)
    }

    func test_mlsMigrationOngoingCall_doesNotContainLinkInAttributedString() throws {
        // given
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationOngoingCall)
        let expectation = self.expectation(description: "")

        // when
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // then
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, _ in
            guard value == nil else { return }
            expectation.fulfill()
        })

        waitForExpectations(timeout: 0.1)
    }

    func test_mlsMigrationUpdateVersion_doesNotContainLinkInAttributedString() throws {
        // given
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationUpdateVersion)
        let expectation = self.expectation(description: "")

        // when
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // then
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, _ in
            guard value == nil else { return }
            expectation.fulfill()
        })

        waitForExpectations(timeout: 0.1)
    }

    func test_mlsMigrationJoinAfterwards_doesContainLinkInAttributedString() throws {
        // given
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationJoinAfterwards)
        let expectation = self.expectation(description: "")

        // when
        let attributedString = try XCTUnwrap(cellDescription.configuration.attributedText)

        // then
        attributedString.enumerateAttribute(.link, in: attributedString.wholeRange, using: { value, _, processPtr in
            guard value != nil else { return }
            expectation.fulfill()
            processPtr.pointee = false
        })

        waitForExpectations(timeout: 0.1)
    }
}
