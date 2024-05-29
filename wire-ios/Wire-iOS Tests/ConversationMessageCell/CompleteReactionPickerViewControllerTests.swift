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

@testable import Wire
import XCTest

final class CompleteReactionPickerViewControllerTests: XCTestCase {

    // MARK: Properties

    var sut: CompleteReactionPickerViewController!
    var emojiRepository: EmojiRepository!

    // MARK: setUp

    override func setUp() {
        super.setUp()
        emojiRepository = EmojiRepository()
        sut = setUpCompleteReactionPickerViewController()
    }

    // MARK: tearDown

    override func tearDown() {
        sut = nil
        emojiRepository.registerRecentlyUsedEmojis([])
        emojiRepository = nil
        super.tearDown()
    }

    // MARK: Snapshot Tests

    func testReactionPicker() {
        sut = setUpCompleteReactionPickerViewController(selectedReactions: ["🐒"])
        scrollToSection(1)
        verify(matching: sut)
    }

    func testReactionPicker_scrolledToMiddle() {
        // GIVEN & WHEN
        sut = setUpCompleteReactionPickerViewController(selectedReactions: ["⛺"])
        scrollToSection(4)

        // THEN
        verify(matching: sut)
    }

    func testReactionPicker_scrolledToBottom() {
        // GIVEN & WHEN
        sut = setUpCompleteReactionPickerViewController(selectedReactions: ["🇦🇷"])
        scrollToSection(7)

        // THEN
        verify(matching: sut)
    }

    func testReactionPicker_withRecentReactionsSection() {
        // GIVEN
        let emojis = ["😂", "🆎", "🫥", "🐞", "🐒"]
        emojiRepository.registerRecentlyUsedEmojis(emojis)
        sut = setUpCompleteReactionPickerViewController(selectedReactions: ["🐒"])

        // THEN
        verify(matching: sut)
    }

    func testReactionPicker_withSearchQuery() {
        // GIVEN & WHEN
        sut = setUpCompleteReactionPickerViewController(selectedReactions: ["🫠"])
        sut = setUpCompleteReactionPickerViewController(selectedReactions: ["🙈"])
        sut.searchBar(UISearchBar(), textDidChange: "face")
        scrollToSection(1)

        // THEN
        verify(matching: sut)
    }

    // MARK: Helper Methods

    private func setUpCompleteReactionPickerViewController(
        selectedReactions: Set<Emoji.ID> = ["😄"]
    ) -> CompleteReactionPickerViewController {
        let vc = CompleteReactionPickerViewController(selectedReactions: selectedReactions)
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()
        return vc
    }

    private func scrollToSection(_ section: Int) {
        sut.view.subviews.forEach {
            if let collectionView = $0 as? UICollectionView {
                collectionView.scrollToItem(at: IndexPath(item: 0, section: section),
                                            at: .top,
                                            animated: false)
            }
        }
    }

}
