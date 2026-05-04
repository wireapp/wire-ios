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

import WireDataModelSupport
import XCTest

@testable import WireDataModel

final class FilterConversationsUseCaseTests: XCTestCase {

    private var sut: FilterConversationsUseCase<MockContainer>!

    override func tearDown() {
        sut = nil
    }

    func testEmptySearchTextReturnsEverything() {

        // Given
        sut = .init(conversationContainers: conversationContainers)

        // When
        let filtered = sut.invoke(query: "")

        // Then
        XCTAssertEqual(filtered, conversationContainers)
    }

    func testSearchTextReturnsNoConversations() {

        // Given
        sut = .init(conversationContainers: conversationContainers)

        // When
        let filtered = sut.invoke(query: "y")

        // Then
        XCTAssertEqual(filtered, [[], [], []])
    }

    func testSearchTextMatchesConversationName() {

        // Given
        sut = .init(conversationContainers: conversationContainers)

        // When
        let filtered = sut.invoke(query: "wire team")

        // Then matches
        // - only the "Wire Team" conversation
        XCTAssertEqual(filtered, [[groupConversations[0]], [], []])
    }

    func testSearchTextMatchesParticipant() {

        // Given
        sut = .init(conversationContainers: conversationContainers)

        // When
        let filtered = sut.invoke(query: "rifka")

        // Then matches
        // - the "Announcements" conversation, since Rifka is a participant
        // - the "Guests" conversation, since Rifka is a participant
        XCTAssertEqual(filtered, [[groupConversations[1]], [], [otherGroupConversations[0]]])
    }

    func testSpecialCharacterMatchesConversationNameAndParticipants() {

        // Given
        sut = .init(conversationContainers: conversationContainers)

        // When
        let filtered = sut.invoke(query: "ö")

        // Then matches
        // - the "Announcements" conversation, because the conversation name contains "o". This is prioritized over
        //   "Wire Team" because conversation names have a higher weight than participant names.
        // - the "Wire Team" conversation, because at least one participant's name contains "o"
        // - the "Pipaluk Bróðir" conversation, because the conversation name contains "o"
        // - the "Guests" conversation, because at least one participant's name contains "o"
        XCTAssertEqual(
            filtered,
            [[groupConversations[1], groupConversations[0]], [oneOnOneConversations[0]], [otherGroupConversations[0]]]
        )
    }

    func testSpecialCharacter_ß_MatchesConversationNameWith_ss() {

        // Given
        sut = .init(conversationContainers: conversationContainers)

        // When
        let filtered = sut.invoke(query: "ß")

        // Then matches
        // - the "Wire Team" conversation, because at least one participant's name contains "o"
        // - the "Announcements" conversation, because the conversation name contains "o"
        // - the "Guests" conversation, because at least one participant's name contains "o"
        XCTAssertEqual(filtered, [[], [], [otherGroupConversations[1], otherGroupConversations[2]]])
    }

    func testCharacters_ss_MatchesConversationNameWith_ß() {

        // Given
        sut = .init(conversationContainers: conversationContainers)

        // When
        let filtered = sut.invoke(query: "ß")

        // Then matches
        // - the "Wire Team" conversation, because at least one participant's name contains "o"
        // - the "Announcements" conversation, because the conversation name contains "o"
        // - the "Guests" conversation, because at least one participant's name contains "o"
        XCTAssertEqual(filtered, [[], [], [otherGroupConversations[1], otherGroupConversations[2]]])
    }

    func testInvoke_sortsMatches() {

        // Given
        let container = MockContainer([
            MockConversation(name: "Tomorrow", otherParticipants: ["Grusha"], isOneOnOne: false),
            MockConversation(name: "Today", otherParticipants: ["Kike"], isOneOnOne: false),
            MockConversation(name: "Guests", otherParticipants: ["Maria"], isOneOnOne: true),
            MockConversation(name: "UI", otherParticipants: ["Peter"], isOneOnOne: true),
            MockConversation(name: "Freedom", otherParticipants: ["Sonny"], isOneOnOne: false),
            MockConversation(name: "Tasks", otherParticipants: ["Yukari"], isOneOnOne: false)

        ])
        sut = .init(conversationContainers: [container])

        // When
        let filtered = sut.invoke(query: "e")

        // Then
        // - the "Guests" conversation matches by name and is moved to the front because it is a one on one.
        // - the "UI" conversation matched by participants and is moved to the front because it is a one on one.
        // - the "Freedom" conversation matches my name. Name matches appear after one on one conversations.
        // - the "Today" conversation matches by participants. Participant matches appear last.
        XCTAssertEqual(filtered, [[
            MockConversation(name: "Guests", otherParticipants: ["Maria"], isOneOnOne: true),
            MockConversation(name: "UI", otherParticipants: ["Peter"], isOneOnOne: true),
            MockConversation(name: "Freedom", otherParticipants: ["Sonny"], isOneOnOne: false),
            MockConversation(name: "Today", otherParticipants: ["Kike"], isOneOnOne: false)
        ]])
    }

    // MARK: - Content

    private var conversationContainers: [MockContainer] {
        [
            MockContainer(groupConversations),
            MockContainer(oneOnOneConversations),
            MockContainer(otherGroupConversations)
        ]
    }

    private let groupConversations = [
        MockConversation(
            name: "Wire Team",
            otherParticipants: [
                "Petrŭ",
                "Mariele",
                "Mneme Tiedemann",
                "Sasho Gréta",
                "Pipaluk Bróðir",
                "Liselot Þórgrímr",
                "Völund Gustavo"
            ],
            isOneOnOne: false
        ),
        MockConversation(
            name: "Announcements",
            otherParticipants: ["Petrŭ", "Rifka", "Mneme Tiedemann", "Pipaluk Bróðir"],
            isOneOnOne: false
        )
    ]

    private let oneOnOneConversations = [
        MockConversation(
            name: "Pipaluk Bróðir",
            otherParticipants: ["Pipaluk Bróðir", "Mneme Tiedemann"],
            isOneOnOne: true
        ),
        MockConversation(name: "Mariele", otherParticipants: ["Mariele", "Mneme Tiedemann"], isOneOnOne: true)
    ]

    private let otherGroupConversations = [
        MockConversation(
            name: "Guests",
            otherParticipants: ["Grusha Žarko", "Rifka", "Mneme Tiedemann"],
            isOneOnOne: false
        ),
        MockConversation(name: "Spaß", otherParticipants: ["Mneme Tiedemann"], isOneOnOne: false),
        MockConversation(name: "Essen", otherParticipants: ["Mneme Tiedemann"], isOneOnOne: false)
    ]
}

// MARK: - Mock Conversation, Mock Container

private struct MockContainer: MutableConversationContainer, CustomDebugStringConvertible, Equatable,
    ExpressibleByArrayLiteral {

    var conversations: [MockConversation]

    var debugDescription: String { "\(conversations)" }

    init(_ conversations: [MockConversation]) {
        self.conversations = conversations
    }

    init(arrayLiteral elements: MockConversation...) {
        self.init(elements)
    }
}

private struct MockConversation: FilterableConversation, CustomDebugStringConvertible, Equatable {

    private(set) var name: String
    private(set) var otherParticipants: [MockParticipant]
    private(set) var isOneOnOne: Bool

    var debugDescription: String {
        let otherParticipants = otherParticipants
            .map(String.init(reflecting:))
            .joined(separator: ", ")
        return "\(name)(\(otherParticipants) + self-user)"
    }
}

private struct MockParticipant: FilterableConversationParticipant, CustomDebugStringConvertible, Equatable,
    ExpressibleByStringLiteral {

    private(set) var name: String

    var debugDescription: String { name }

    init(stringLiteral value: String) {
        self.name = value
    }
}
