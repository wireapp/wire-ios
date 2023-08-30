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

@testable import Wire
import XCTest

final class CompleteReactionPickerViewControllerTests: BaseSnapshotTestCase {

    // MARK: Properties

    var sut: CompleteReactionPickerViewController!

    // MARK: setUp

    override func setUp() {
        super.setUp()
        sut = setUpCompleteReactionPickerViewController()
    }

    // MARK: tearDown

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: Snapshot Tests

    func testReactionPicker() {
        sut = setUpCompleteReactionPickerViewController(selectedReactions: [.monkey])
        scrollToSection(1)
        verify(matching: sut)
    }

    func testReactionPicker_scrolledToMiddle() {
        // GIVEN & WHEN
        sut = setUpCompleteReactionPickerViewController(selectedReactions: [.videoGameController])
        scrollToSection(4)

        // THEN
        verify(matching: sut)
    }

    func testReactionPicker_scrolledToBottom() {
        // GIVEN & WHEN
        sut = setUpCompleteReactionPickerViewController(selectedReactions: [.argentinaFlag])
        scrollToSection(7)
        // THEN
        verify(matching: sut)
    }

    // MARK: Helper Methods

    private func setUpCompleteReactionPickerViewController(
        selectedReactions: Set<Emoji> = [.smile]
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

// MARK: - Emoji extension

fileprivate extension Emoji {

    static var videoGameController: Emoji {
        return Emoji(value: "🎮")
    }

    static var argentinaFlag: Emoji {
        return Emoji(value: "🇦🇷")
    }

    static var monkey: Emoji {
        return Emoji(value: "🐒")
    }
}
