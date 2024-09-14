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

import WireTestingPackage
import XCTest

@testable import Wire

final class BasicReactionPickerSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper_!
    private var picker: BasicReactionPicker!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        picker = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func test_BasicReactionPicker() {
        // GIVEN && WHEN
        picker = pickerWithReaction(nil)

        // THEN
        snapshotHelper.verify(matching: picker)
    }

    func test_BasicReactionPicker_withSelectedReaction() {
        // GIVEN && WHEN
        picker = pickerWithReaction([Emoji.ID.thumbsUp])

        // THEN
        snapshotHelper.verify(matching: picker)
    }

    // MARK: - Helper method

    private func pickerWithReaction(_ reaction: Set<Emoji.ID>?) -> BasicReactionPicker {
        picker = BasicReactionPicker(selectedReactions: reaction ?? [])
        picker.sizeToFit()
        picker.backgroundColor = .white
        picker.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: 84))

        return picker
    }
}
