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

import WireDataModelSupport
import XCTest

@testable import WireDataModel

final class SearchConversationsUseCaseTests: XCTestCase {

    private var sut: SearchConversationsUseCase<MockContainer>!

    override func tearDown() {
        sut = nil
    }

    func testEmptySearchTextReturnsEverything() {

        // Given
        sut = .init(conversationContainers: conversationContainers)

        // When
        let filtered = sut.invoke(searchText: "")

        // Then
        XCTAssertEqual(filtered, conversationContainers)
    }

    func testSingleCharacterSearchTextReturnsNoConversations() {

        // Given
        sut = .init(conversationContainers: conversationContainers)

        // When
        let filtered = sut.invoke(searchText: "y")

        // Then
        XCTAssertEqual(filtered, [[], [], []])
    }

    // MARK: - Content

    private var conversationContainers: [MockContainer] {
        [
            MockContainer(groupConversations),
            MockContainer(oneOnOneConversations),
            MockContainer(otherFolder)
        ]
    }

    private let groupConversations = [
        MockConversation(
            searchableName: "Wire Team",
            searchableParticipants: ["Petrŭ", "Mariele", "Mneme Tiedemann", "Sasho Gréta", "Pipaluk Bróðir", "Liselot Þórgrímr", "Völund Gustavo"]
        ),
        MockConversation(searchableName: "Announcements", searchableParticipants: ["Petrŭ", "Rifka", "Mneme Tiedemann", "Pipaluk Bróðir"])
    ]

    private let oneOnOneConversations = [
        MockConversation(searchableName: "Pipaluk Bróðir", searchableParticipants: ["Pipaluk Bróðir", "Mneme Tiedemann"]),
        MockConversation(searchableName: "Mariele", searchableParticipants: ["Mariele", "Mneme Tiedemann"])
    ]

    private let otherFolder = [
        MockConversation(searchableName: "Guests", searchableParticipants: ["Grusha Žarko", "Mneme Tiedemann"])
    ]
}

// MARK: - Mock Conversation, Mock Container

private struct MockContainer: SearchableConversationContainer, CustomDebugStringConvertible, Equatable, ExpressibleByArrayLiteral {

    private(set) var conversations: [MockConversation]

    var debugDescription: String {
        "Container(\(conversations))"
    }

    init(_ conversations: [MockConversation]) {
        self.conversations = conversations
    }

    init(arrayLiteral elements: MockConversation...) {
        self.init(elements)
    }

    mutating func removeConversation(at index: Int) {
        conversations.remove(at: index)
    }
}

private struct MockConversation: SearchableConversation, CustomDebugStringConvertible, Equatable {

    private(set) var searchableName: String
    private(set) var searchableParticipants: [MockParticipant]

    var debugDescription: String {
        "Conversation(\(searchableName), \(searchableParticipants))"
    }
}

private struct MockParticipant: SearchableConversationParticipant, CustomDebugStringConvertible, Equatable, ExpressibleByStringLiteral {

    private(set) var searchableName: String

    var debugDescription: String {
        "Participant(\(searchableName))"
    }

    init(stringLiteral value: String) {
        searchableName = value
    }
}
