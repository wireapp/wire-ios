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

import Foundation
import Testing
import WireFoundation
import WireFoundationSupport

@testable import WireCallingDomain
@testable import WireCallingDomainSupport

@Suite("FetchUpcomingMeetingsUseCase Tests")
struct FetchUpcomingMeetingsUseCaseTests {

    private let repository = MeetingRepositoryProtocolMock()
    private let calendar = Calendar.current

    @Test("invoke fetches upcoming meetings from repository")
    func invokeFetchesMeetings() async throws {
        // Given
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")

        let meeting1 = Meeting.fixture(title: "Meeting 1", start: mockDateProvider.now.addingTimeInterval(3600))
        let meeting2 = Meeting.fixture(title: "Meeting 2", start: mockDateProvider.now.addingTimeInterval(7200))
        repository.fetchMeetingsStartingAfterDateDateOffsetIntLimitIntMeetingReturnValue = [meeting1, meeting2]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 10, offset: 0)

        // Then
        #expect(result.meetings.count == 2)
        #expect(result.meetings.contains { $0.title == "Meeting 1" })
        #expect(result.meetings.contains { $0.title == "Meeting 2" })
    }

    @Test("invoke returns empty result when no upcoming meetings")
    func invoke_WithNoMeetings() async throws {
        // Given
        repository.fetchMeetingsStartingAfterDateDateOffsetIntLimitIntMeetingReturnValue = []
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 10, offset: 0)

        // Then
        #expect(result.meetings.isEmpty)
        #expect(!result.hasMore)
    }

    @Test("invoke returns hasMore true when more meetings exist than pageSize")
    func invoke_WithMoreMeetingsThanPageSize() async throws {
        // Given
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")

        let meetings = (0 ... 12).map { index in
            Meeting.fixture(
                title: "Meeting \(index)",
                start: mockDateProvider.now.addingTimeInterval(TimeInterval(index * 3600))
            )
        }
        repository.fetchMeetingsStartingAfterDateDateOffsetIntLimitIntMeetingReturnValue = meetings

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 10, offset: 0)

        // Then
        #expect(result.hasMore)
        #expect(result.meetings.count == 10)
    }

    @Test("invoke returns hasMore false when meetings count equals pageSize")
    func invoke_WithExactlyPageSizeMeetings() async throws {
        // Given
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")

        let meetings = (0 ..< 10).map { index in
            Meeting.fixture(
                title: "Meeting \(index)",
                start: mockDateProvider.now.addingTimeInterval(TimeInterval(index * 3600))
            )
        }
        repository.fetchMeetingsStartingAfterDateDateOffsetIntLimitIntMeetingReturnValue = meetings

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 10, offset: 0)

        // Then
        #expect(!result.hasMore)
        #expect(result.meetings.count == 10)
    }

}

private extension Meeting {

    static func fixture(
        id: QualifiedID = QualifiedID(id: UUID(), domain: ""),
        title: String,
        start: Date,
        duration: TimeInterval = 3600
    ) -> Meeting {
        Meeting(
            id: id,
            title: title,
            start: start,
            end: start.addingTimeInterval(duration),
            recurrence: nil,
            members: [],
            conversationID: QualifiedID(id: UUID(), domain: "")
        )
    }

}
