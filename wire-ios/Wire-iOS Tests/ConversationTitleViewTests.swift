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

final class ConversationTitleViewTests: XCTestCase {

    // MARK: - Properties

    private var sut: ConversationTitleView!
    private var conversation: MockGroupDetailsConversation!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        conversation = MockGroupDetailsConversation()
        conversation.relatedConnectionState = .accepted
        conversation.displayName = "Alan Turing"

        snapshotHelper = .init()
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        conversation = nil
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Helper method

    private func createSut(conversation: MockGroupDetailsConversation) -> ConversationTitleView {
        let view = ConversationTitleView(conversation: conversation, interactive: true)
        view.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 44))
        view.backgroundColor = .white
        return view
    }

    // MARK: - Snapshot Tests

    func testThatItRendersTheConversationDisplayNameCorrectly() {
        // GIVEN && WHEN
        sut = createSut(conversation: conversation)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersTheFederatedConversationDisplayNameCorrectly() {
        // GIVEN && WHEN
        let user = MockUserType.createUser(name: "Alan Turing")
        user.isFederated = true
        user.domain = "wire.com"
        user.handle = "alanturing"
        conversation.connectedUserType = user
        conversation.conversationType = .oneOnOne
        sut = createSut(conversation: conversation)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersTheVerifiedShieldCorrectly() {
        // GIVEN && WHEN
        conversation.securityLevel = .secure
        sut = createSut(conversation: conversation)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersValidCertificate() {
        // GIVEN && WHEN
        conversation.messageProtocol = .mls
        conversation.isE2EIEnabled = true
        conversation.mlsVerificationStatus = .verified
        sut = createSut(conversation: conversation)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersLegalHoldCorrectly() {
        // GIVEN && WHEN
        conversation.isUnderLegalHold = true
        sut = createSut(conversation: conversation)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItUpdatesTheTitleViewAndRendersLegalHoldAndVerifiedShieldCorrectly() {
        // GIVEN && WHEN
        conversation.securityLevel = .secure
        conversation.isUnderLegalHold = true
        sut = createSut(conversation: conversation)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItDoesNotRenderTheDownArrowForOutgoingConnections() {
        // GIVEN && WHEN
        conversation.relatedConnectionState = .sent
        sut = createSut(conversation: conversation)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Unit Test

    func testThatItExecutesTheTapHandlerOnTitleTap() {
        // GIVEN
        sut = ConversationTitleView(conversation: conversation, interactive: true)

        var callCount: Int = 0
        sut.tapHandler = { _ in
            callCount += 1
        }

        XCTAssertEqual(callCount, 0)

        // WHEN
        sut.titleButton.sendActions(for: .touchUpInside)

        // THEN
        XCTAssertEqual(callCount, 1)
    }
}
