//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


@testable import ZMCDataModel


class SharedModifiedConversationsListTests: BaseZMMessageTests {

    var sut: SharedModifiedConversationsList!

    override func setUp() {
        super.setUp()
        sut = SharedModifiedConversationsList()
    }

    override func tearDown() {
        sut.clear()
        super.tearDown()
    }

    func testThatItCanStoreAndReadAConversation() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // When
        sut.add(conversation)

        // Then
        XCTAssertEqual(sut.storedIdentifiers, [conversation.remoteIdentifier!])
    }

    func testThatItCanClearTheStoredIdentifiers() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        sut.add(conversation)
        XCTAssertEqual(sut.storedIdentifiers, [conversation.remoteIdentifier!])

        // When
        sut.clear()

        // Then
        XCTAssertEqual(sut.storedIdentifiers, [])

    }

    func testThatItCanSaveMultipleConversations() {
        // Given
        let firstConversation = ZMConversation.insertNewObject(in: uiMOC)
        firstConversation.remoteIdentifier = .create()
        let secondConversation = ZMConversation.insertNewObject(in: uiMOC)
        secondConversation.remoteIdentifier = .create()

        // When
        sut.add(firstConversation)

        // Then
        XCTAssertEqual(sut.storedIdentifiers, [firstConversation.remoteIdentifier!])

        // When
        sut.add(secondConversation)

        // Then
        XCTAssertEqual(sut.storedIdentifiers, [firstConversation.remoteIdentifier!, secondConversation.remoteIdentifier!])
    }

    func testThatItAddsAConversationAddedMultipleTimesOnce() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // When
        sut.add(conversation)

        // Then
        XCTAssertEqual(sut.storedIdentifiers, [conversation.remoteIdentifier!])

        // When
        sut.add(conversation)

        // Then
        XCTAssertEqual(sut.storedIdentifiers, [conversation.remoteIdentifier!])
    }

}


