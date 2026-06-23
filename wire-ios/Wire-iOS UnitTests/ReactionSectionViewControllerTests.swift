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

    func testPanGestureTargetsInstance() {
        // GIVEN
        let sut = ReactionSectionViewController(types: EmojiSectionType.allCases)
        _ = sut.view

        // WHEN
        let pan = sut.view.gestureRecognizers?.first(where: { $0 is UIPanGestureRecognizer })

        // THEN — target must be the instance, not the class; calling didPan: on the class crashes
        let targets = pan?.value(forKey: "targets") as? [NSObject]
        let target = targets?.first?.value(forKey: "target")
        XCTAssert(target is ReactionSectionViewController, "pan gesture target must be an instance, not the class — sending didPan: to the class crashes (WPB-XXXX)")
    }

}
