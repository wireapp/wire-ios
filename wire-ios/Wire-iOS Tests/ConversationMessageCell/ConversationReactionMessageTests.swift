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

import WireTestingPackage
import XCTest

@testable import Wire

final class ConversationReactionMessageTests: ConversationMessageSnapshotTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: MessageReactionsCell!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        sut = MessageReactionsCell()
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.widthAnchor.constraint(equalToConstant: 375).isActive = true
        // We need to pass an estimated cell size to help the cell layout properly
        sut.systemLayoutSizeFitting(CGSize(width: 375, height: 100))
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    func testReactionAccessibilityMetadata() {
        let toggle = ReactionToggle(emoji: "👍", count: 4, userSession: userSession)

        XCTAssertTrue(toggle.isAccessibilityElement)
        XCTAssertEqual(toggle.accessibilityIdentifier, "value: 👍, count: 4")
        XCTAssertEqual(toggle.accessibilityLabel, "👍")
        XCTAssertEqual(toggle.accessibilityValue, "4")
        XCTAssertTrue(toggle.accessibilityTraits.contains(.button))
        XCTAssertFalse(toggle.accessibilityTraits.contains(.selected))
        XCTAssertEqual(toggle.accessibilityHint, L10n.Accessibility.Reaction.addHint)
    }

    func testReactionAccessibilityUpdatesSelectedState() {
        let toggle = ReactionToggle(emoji: "👍", count: 1, userSession: userSession)

        toggle.isToggled = true
        XCTAssertTrue(toggle.accessibilityTraits.contains(.button))
        XCTAssertTrue(toggle.accessibilityTraits.contains(.selected))
        XCTAssertEqual(toggle.accessibilityHint, L10n.Accessibility.Reaction.removeHint)

        toggle.isToggled = false
        XCTAssertFalse(toggle.accessibilityTraits.contains(.selected))
        XCTAssertEqual(toggle.accessibilityHint, L10n.Accessibility.Reaction.addHint)
    }

    func testReactionAccessibilityActivationDispatchesExistingTargets() {
        var toggleCount = 0
        var additionalTargetCount = 0
        let toggle = ReactionToggle(emoji: "👍", count: 1, userSession: userSession) { toggleCount += 1 }
        toggle.addAction(UIAction { _ in additionalTargetCount += 1 }, for: .touchUpInside)

        XCTAssertTrue(toggle.accessibilityActivate())
        XCTAssertEqual(toggleCount, 1)
        XCTAssertEqual(additionalTargetCount, 1)

        toggle.sendActions(for: .touchUpInside)
        XCTAssertEqual(toggleCount, 2)
        XCTAssertEqual(additionalTargetCount, 2)
    }

    func testDisabledReactionAccessibilityActivationDoesNotDispatch() {
        var toggleCount = 0
        let toggle = ReactionToggle(emoji: "👍", count: 1, userSession: userSession) { toggleCount += 1 }
        toggle.isEnabled = false

        XCTAssertFalse(toggle.accessibilityActivate())
        XCTAssertEqual(toggleCount, 0)
        XCTAssertFalse(toggle.isEnabled)
    }

    func testReconfigurationRefreshesReactionAccessibilityCountAndSelection() throws {
        func toggles(in view: UIView) -> [ReactionToggle] {
            if let toggle = view as? ReactionToggle { return [toggle] }
            return view.subviews.flatMap { toggles(in: $0) }
        }

        sut.configure(with: .init(
            reactions: [.init(emoji: "👍", count: 1, isSelfUserReacting: false)],
            userSession: userSession
        ), animated: false)
        let originalToggle = try XCTUnwrap(toggles(in: sut).first)
        XCTAssertEqual(originalToggle.accessibilityValue, "1")

        sut.configure(with: .init(
            reactions: [.init(emoji: "👍", count: 3, isSelfUserReacting: true)],
            userSession: userSession
        ), animated: false)
        let currentToggles = toggles(in: sut)
        let currentToggle = try XCTUnwrap(currentToggles.first)
        XCTAssertEqual(currentToggles.count, 1)
        XCTAssertFalse(currentToggle === originalToggle)
        XCTAssertEqual(currentToggle.accessibilityValue, "3")
        XCTAssertEqual(currentToggle.accessibilityIdentifier, "value: 👍, count: 3")
        XCTAssertTrue(currentToggle.accessibilityTraits.contains(.selected))
        XCTAssertEqual(currentToggle.accessibilityHint, L10n.Accessibility.Reaction.removeHint)
    }

    // MARK: - Snapshot Tests

    func testThatItConfiguresWithSelfReaction() {
        // GIVEN
        let reaction = MessageReactionMetadata(emoji: .like, count: 1, isSelfUserReacting: true)
        let configuration = MessageReactionsCell.Configuration(
            reactions: [reaction],
            userSession: userSession
        )
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItConfiguresWithOtherReactions() {
        // GIVEN
        let likeReaction = MessageReactionMetadata(
            emoji: .like,
            count: 4,
            isSelfUserReacting: false
        )

        let thumbsUpReaction = MessageReactionMetadata(
            emoji: .thumbsUp,
            count: 1,
            isSelfUserReacting: false
        )

        let thumbsDownReaction = MessageReactionMetadata(
            emoji: .thumbsDown,
            count: 6,
            isSelfUserReacting: false
        )

        let slightlySmilingReaction = MessageReactionMetadata(
            emoji: .smile,
            count: 8,
            isSelfUserReacting: false
        )

        let frowningFaceReaction = MessageReactionMetadata(
            emoji: .frown,
            count: 10,
            isSelfUserReacting: false
        )

        let reaction = [
            likeReaction,
            thumbsUpReaction,
            thumbsDownReaction,
            slightlySmilingReaction,
            frowningFaceReaction
        ]
        let configuration = MessageReactionsCell.Configuration(
            reactions: reaction,
            userSession: userSession
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }
}
