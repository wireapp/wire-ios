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

import UIKit
import XCTest

@testable import Wire

final class ConversationOfflineNoticeCellTests: XCTestCase {

    @MainActor
    func testNoticeIsAccessibleWithFullText() {
        let description = ConversationOfflineNoticeCellDescription()
        let cell = ConversationOfflineNoticeCell(frame: .zero)

        description.configureContentView(cell)

        XCTAssertTrue(cell.isAccessibilityElement)
        XCTAssertEqual(cell.accessibilityLabel, description.configuration.attributedText.string)
        XCTAssertEqual(cell.accessibilityIdentifier, "offline_notice")
        XCTAssertFalse(cell.textLabel.isAccessibilityElement)
        XCTAssertFalse(cell.imageView.isAccessibilityElement)
    }

    @MainActor
    func testBothFontsUpdateWhenContentSizeCategoryChanges() throws {
        let description = ConversationOfflineNoticeCellDescription()
        let cell = ConversationOfflineNoticeCell(frame: .zero)
        cell.traitOverrides.preferredContentSizeCategory = .large
        cell.updateTraitsIfNeeded()
        description.configureContentView(cell)
        let originalText = try XCTUnwrap(cell.attributedText)

        cell.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        cell.updateTraitsIfNeeded()
        XCTAssertEqual(cell.traitCollection.preferredContentSizeCategory, .accessibilityExtraExtraExtraLarge)

        let scaledText = try XCTUnwrap(cell.attributedText)
        for index in [0, scaledText.length - 1] {
            let originalFont = try XCTUnwrap(originalText.attribute(.font, at: index, effectiveRange: nil) as? UIFont)
            let scaledFont = try XCTUnwrap(scaledText.attribute(.font, at: index, effectiveRange: nil) as? UIFont)
            XCTAssertGreaterThan(scaledFont.pointSize, originalFont.pointSize)
            XCTAssertEqual(scaledFont.fontDescriptor.symbolicTraits, originalFont.fontDescriptor.symbolicTraits)
        }
        XCTAssertEqual(scaledText.string, originalText.string)
        cell.frame = CGRect(x: 0, y: 0, width: 320, height: 500)
        cell.layoutIfNeeded()
        XCTAssertGreaterThanOrEqual(cell.textLabel.frame.minY, 0)

        cell.traitOverrides.preferredContentSizeCategory = .large
        cell.updateTraitsIfNeeded()
        XCTAssertEqual(cell.attributedText, originalText)
    }
}
