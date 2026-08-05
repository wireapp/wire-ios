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
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [meeting1, meeting2]

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
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = []
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
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = meetings

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
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = meetings

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

    @Test("invoke returns meetings from the start of today, including meetings earlier today")
    func invoke_ReturnsMeetingsFromToday() async throws {
        // Given
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: try Date.ISO8601FormatStyle().parse("2026-07-11T12:00:00Z"))
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = startOfToday.addingTimeInterval(12 * 3600)

        let yesterday = Meeting.fixture(title: "Yesterday", start: startOfToday.addingTimeInterval(-3600))
        let earlierToday = Meeting.fixture(title: "Earlier today", start: startOfToday.addingTimeInterval(5 * 60))
        let tomorrow = Meeting.fixture(title: "Tomorrow", start: startOfToday.addingTimeInterval(24 * 3600))
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [
            yesterday,
            earlierToday,
            tomorrow
        ]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 10, offset: 0)

        // Then
        #expect(result.meetings.map(\.title) == ["Earlier today", "Tomorrow"])

        let range = repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReceivedArguments?.range
        #expect(range?.lowerBound == Date.distantPast)
        #expect(range?.upperBound == Date.distantFuture)
        #expect(repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReceivedArguments?.offset == 0)
    }

    @Test("invoke expands a daily repeated meeting into upcoming occurrence rows")
    func invoke_ExpandsDailyRecurrence() async throws {
        // Given
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: try Date.ISO8601FormatStyle().parse("2026-07-11T12:00:00Z"))
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = startOfToday.addingTimeInterval(12 * 3600)

        let sourceStart = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
            .addingTimeInterval(9 * 3600)
        let meeting = Meeting.fixture(
            title: "Daily sync",
            start: sourceStart,
            duration: 30 * 60,
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [meeting]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 3, offset: 0)

        // Then
        #expect(result.occurrences.map(\.start) == [
            startOfToday.addingTimeInterval(9 * 3600),
            startOfToday.addingTimeInterval(33 * 3600),
            startOfToday.addingTimeInterval(57 * 3600)
        ])
        #expect(result.occurrences.allSatisfy { $0.meeting == meeting })
        #expect(result.hasMore)
        #expect(result.nextOffset == 3)
    }

    @Test("invoke fast-forwards daily recurrences that started years before today")
    func invoke_FastForwardsLongRunningDailyRecurrence() async throws {
        // Given
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: try Date.ISO8601FormatStyle().parse("2026-07-11T12:00:00Z"))
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = startOfToday.addingTimeInterval(12 * 3600)

        let sourceStart = calendar.date(
            byAdding: .year,
            value: -6,
            to: startOfToday.addingTimeInterval(9 * 3600)
        )!
        let meeting = Meeting.fixture(
            title: "Daily sync",
            start: sourceStart,
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [meeting]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 2, offset: 0)

        // Then
        #expect(result.occurrences.map(\.start) == [
            startOfToday.addingTimeInterval(9 * 3600),
            startOfToday.addingTimeInterval(33 * 3600)
        ])
        #expect(result.hasMore)
        #expect(result.nextOffset == 2)
    }

    @Test("invoke paginates repeated meeting occurrences")
    func invoke_PaginatesRepeatedOccurrences() async throws {
        // Given
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: try Date.ISO8601FormatStyle().parse("2026-07-11T12:00:00Z"))
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = startOfToday.addingTimeInterval(12 * 3600)

        let sourceStart = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
            .addingTimeInterval(9 * 3600)
        let meeting = Meeting.fixture(
            title: "Daily sync",
            start: sourceStart,
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [meeting]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 2, offset: 2)

        // Then
        #expect(result.occurrences.map(\.start) == [
            startOfToday.addingTimeInterval(57 * 3600),
            startOfToday.addingTimeInterval(81 * 3600)
        ])
        #expect(result.nextOffset == 4)
    }

    @Test("invoke clamps negative offsets to the first page")
    func invoke_ClampsNegativeOffset() async throws {
        // Given
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: try Date.ISO8601FormatStyle().parse("2026-07-11T12:00:00Z"))
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = startOfToday.addingTimeInterval(12 * 3600)

        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [
            Meeting.fixture(title: "First", start: startOfToday.addingTimeInterval(9 * 3600)),
            Meeting.fixture(title: "Second", start: startOfToday.addingTimeInterval(10 * 3600)),
            Meeting.fixture(title: "Third", start: startOfToday.addingTimeInterval(11 * 3600))
        ]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 2, offset: -5)

        // Then
        #expect(result.meetings.map(\.title) == ["First", "Second"])
        #expect(result.hasMore)
        #expect(result.nextOffset == 2)
    }

    @Test("invoke reuses the source meeting snapshot when loading subsequent pages")
    func invoke_ReusesSourceMeetingSnapshotForSubsequentPages() async throws {
        // Given
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2026-07-11T12:00:00Z")

        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [
            Meeting.fixture(title: "First", start: mockDateProvider.now.addingTimeInterval(3600)),
            Meeting.fixture(title: "Second", start: mockDateProvider.now.addingTimeInterval(7200)),
            Meeting.fixture(title: "Third", start: mockDateProvider.now.addingTimeInterval(10_800))
        ]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let firstPage = try await useCase.invoke(pageSize: 2, offset: 0)
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [
            Meeting.fixture(title: "Refetched", start: mockDateProvider.now.addingTimeInterval(14_400))
        ]
        let secondPage = try await useCase.invoke(pageSize: 2, offset: firstPage.nextOffset)

        // Then
        #expect(repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingCallsCount == 1)
        #expect(firstPage.meetings.map(\.title) == ["First", "Second"])
        #expect(secondPage.meetings.map(\.title) == ["Third"])
        #expect(!secondPage.hasMore)
    }

    @Test("invoke refreshes the source meeting snapshot when pagination restarts")
    func invoke_RefreshesSourceMeetingSnapshotWhenOffsetIsZero() async throws {
        // Given
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2026-07-11T12:00:00Z")

        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [
            Meeting.fixture(title: "Initial", start: mockDateProvider.now.addingTimeInterval(3600))
        ]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let initialPage = try await useCase.invoke(pageSize: 2, offset: 0)
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [
            Meeting.fixture(title: "Refreshed", start: mockDateProvider.now.addingTimeInterval(7200))
        ]
        let refreshedPage = try await useCase.invoke(pageSize: 2, offset: 0)

        // Then
        #expect(repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingCallsCount == 2)
        #expect(initialPage.meetings.map(\.title) == ["Initial"])
        #expect(refreshedPage.meetings.map(\.title) == ["Refreshed"])
    }

    @Test("invoke stops recurrence expansion at the until date")
    func invoke_StopsAtRecurrenceUntilDate() async throws {
        // Given
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: try Date.ISO8601FormatStyle().parse("2026-07-11T12:00:00Z"))
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = startOfToday.addingTimeInterval(12 * 3600)

        let occurrenceStart = startOfToday.addingTimeInterval(9 * 3600)
        let sourceStart = calendar.date(byAdding: .day, value: -1, to: occurrenceStart)!
        let meeting = Meeting.fixture(
            title: "Daily sync",
            start: sourceStart,
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1, until: occurrenceStart)
        )
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [meeting]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 10, offset: 0)

        // Then
        #expect(result.occurrences.map(\.start) == [occurrenceStart])
        #expect(!result.hasMore)
    }

    @Test("invoke caps page size at twenty occurrence rows")
    func invoke_CapsPageSizeAtTwentyOccurrences() async throws {
        // Given
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: try Date.ISO8601FormatStyle().parse("2026-07-11T12:00:00Z"))
        let mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = startOfToday.addingTimeInterval(12 * 3600)

        let meeting = Meeting.fixture(
            title: "Daily sync",
            start: startOfToday.addingTimeInterval(9 * 3600),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )
        repository.fetchMeetingsInRangeRangeDateOffsetIntLimitIntMeetingReturnValue = [meeting]

        let useCase = FetchUpcomingMeetingsUseCase(
            repository: repository,
            currentDateProvider: mockDateProvider
        )

        // When
        let result = try await useCase.invoke(pageSize: 50, offset: 0)

        // Then
        #expect(result.occurrences.count == 20)
        #expect(result.hasMore)
    }

}

private extension Meeting {

    static func fixture(
        id: QualifiedID = QualifiedID(id: UUID(), domain: ""),
        title: String,
        start: Date,
        duration: TimeInterval = 3600,
        recurrence: MeetingRecurrence? = nil
    ) -> Meeting {
        Meeting(
            id: id,
            title: title,
            start: start,
            end: start.addingTimeInterval(duration),
            recurrence: recurrence,
            conversationID: QualifiedID(id: UUID(), domain: ""),
            creatorID: QualifiedID(id: UUID(), domain: "")
        )
    }

}
