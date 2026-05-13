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

final class LegalHoldDetailsViewModelTests: XCTestCase {

    override func tearDown() {
        SelfUser.provider = nil

        super.tearDown()
    }

    func testThatItUsesSelfDescription_WhenSelfUserIsUnderLegalHold() {
        let conversation = MockGroupDetailsConversation()
        SelfUser.setupMockSelfUser(inTeam: UUID())
        let selfUser = SelfUser.provider?.providedSelfUser as! MockUserType
        selfUser.isUnderLegalHold = true

        let sut = LegalHoldDetailsViewModel(conversation: conversation, selfUser: selfUser)

        XCTAssertEqual(sut.header.title, L10n.Localizable.Legalhold.Header.title)
        XCTAssertEqual(sut.header.description, L10n.Localizable.Legalhold.Header.selfDescription)
    }

    func testThatItUsesOtherDescription_WhenSelfUserIsNotUnderLegalHold() {
        let conversation = MockGroupDetailsConversation()
        SelfUser.setupMockSelfUser(inTeam: UUID())
        let selfUser = SelfUser.provider?.providedSelfUser as! MockUserType
        selfUser.isUnderLegalHold = false

        let sut = LegalHoldDetailsViewModel(conversation: conversation, selfUser: selfUser)

        XCTAssertEqual(sut.header.description, L10n.Localizable.Legalhold.Header.otherDescription)
    }

    func testThatParticipantsSectionContainsOnlyLegalHoldSubjects() {
        let conversation = MockGroupDetailsConversation()
        let users = Array(SwiftMockLoader.mockUsers().prefix(3))
        users[0].isUnderLegalHold = false
        users[1].isUnderLegalHold = true
        users[2].isUnderLegalHold = true
        conversation.sortedActiveParticipantsUserTypes = users

        let sut = LegalHoldDetailsViewModel(conversation: conversation, selfUser: nil)

        XCTAssertEqual(sut.participantsSection.participants.count, 2)
        XCTAssertTrue(sut.participantsSection.participants[0] === users[1])
        XCTAssertTrue(sut.participantsSection.participants[1] === users[2])
        XCTAssertEqual(sut.participantsSection.accessibilityIdentifier, "label.groupdetails.participants")
    }

    func testThatSectionsContainHeaderAndParticipants() {
        let conversation = MockGroupDetailsConversation()

        let sut = LegalHoldDetailsViewModel(conversation: conversation, selfUser: nil)

        XCTAssertEqual(sut.sections, [.header, .participants])
    }

    func testThatItProvidesCollectionAccessibilityIdentifier() {
        let conversation = MockGroupDetailsConversation()

        let sut = LegalHoldDetailsViewModel(conversation: conversation, selfUser: nil)

        XCTAssertEqual(sut.collectionAccessibilityIdentifier, "list.legalhold")
    }

}
