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

final class BasicReactionPickerSnapshotTests: XCTestCase {

    // MARK: - Snapshot Tests

    func test_BasicReactionPicker() {
        // GIVEN && WHEN
        let sut = pickerWithReaction(nil)

        // THEN
        verify(matching: sut)
    }

    func test_BasicReactionPicker_withSelectedReaction() {
        // GIVEN && WHEN
        let sut = pickerWithReaction([Emoji.ID.thumbsUp])

        // THEN
        verify(matching: sut)
    }

    // MARK: - Helper method

    private func pickerWithReaction(_ reaction: Set<Emoji.ID>?) -> BasicReactionPicker {
        var picker = BasicReactionPicker(selectedReactions: reaction ?? [])
        picker.sizeToFit()
        picker.backgroundColor = .white
        picker.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: 84))

        return picker
    }
}
