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

final class ReactionSectionViewControllerTests: XCTestCase {

    @MainActor
    func testPanGestureTargetsInstance() throws {
        // GIVEN
        let sut = ReactionSectionViewController(types: EmojiSectionType.allCases)
        _ = sut.view

        // WHEN
        let pan = try XCTUnwrap(sut.view.gestureRecognizers?
            .first { $0 is UIPanGestureRecognizer } as? UIPanGestureRecognizer)

        // THEN — target must be the same instance, not the class; sending didPan: to the class crashes
        let targets = try XCTUnwrap(pan.value(forKey: "targets") as? [NSObject])
        let target = try XCTUnwrap(targets.first?.value(forKey: "target") as AnyObject?)
        XCTAssertTrue(
            target === sut,
            "pan gesture target must be the ReactionSectionViewController instance — sending didPan: to the class crashes (WPB-26550)"
        )
    }

}
