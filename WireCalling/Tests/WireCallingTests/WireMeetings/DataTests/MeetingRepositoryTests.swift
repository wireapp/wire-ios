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
import WireNetwork
import WireNetworkSupport

@testable import WireCallingData
@testable import WireCallingDomain
@testable import WireCallingDomainSupport

@Suite("MeetingRepository Tests")
struct MeetingRepositoryTests {

    private let meetingsAPI = MockMeetingsAPI()
    private let localStore = MeetingLocalStoreProtocolMock()
    private let sut: MeetingRepository

    init() {
        // Participant changes are covered by their own test, everywhere else
        // the stream must only not emit.
        localStore.observeMeetingConversationChangesAsyncStreamVoidReturnValue = AsyncStream { $0.finish() }

        self.sut = MeetingRepository(
            meetingsAPI: meetingsAPI,
            localStore: localStore
        )
    }

    // MARK: - pullMeeting

    @Test
    func pullMeetingStoresMeetingContainedInBackendResponse() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = [Scaffolding.meetingResponse]

        // When

        let meeting = try await sut.pullMeeting(id: Scaffolding.meetingID)

        // Then

        #expect(meeting?.id == Scaffolding.meetingID)
        #expect(localStore.storeMeetingMeetingMeetingVoidReceivedInvocations.count == 1)
        #expect(localStore.storeMeetingMeetingMeetingVoidReceivedInvocations.first?.id == Scaffolding.meetingID)
        #expect(
            localStore.storeMeetingMeetingMeetingVoidReceivedInvocations.first?.title
                == Scaffolding.meetingResponse.title
        )
        #expect(
            localStore.storeMeetingMeetingMeetingVoidReceivedInvocations.first?.creatorID
                == Scaffolding.meetingResponse.creatorID
        )
        #expect(localStore.deleteMeetingIdQualifiedIDVoidReceivedInvocations.isEmpty)
    }

    @Test
    func pullMeetingDeletesMeetingMissingFromBackendResponse() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = []

        // When

        let meeting = try await sut.pullMeeting(id: Scaffolding.meetingID)

        // Then

        #expect(meeting == nil)
        #expect(localStore.storeMeetingMeetingMeetingVoidReceivedInvocations.isEmpty)
        #expect(localStore.deleteMeetingIdQualifiedIDVoidReceivedInvocations == [Scaffolding.meetingID])
    }

    @Test
    func pullMeetingThrowsWhenListingMeetingsFails() async {
        // Mock

        meetingsAPI.listMeetings_MockError = MeetingsAPIError.meetingNotFound

        // When / Then

        await #expect(throws: (any Error).self) {
            try await sut.pullMeeting(id: Scaffolding.meetingID)
        }
        #expect(localStore.storeMeetingMeetingMeetingVoidReceivedInvocations.isEmpty)
        #expect(localStore.deleteMeetingIdQualifiedIDVoidReceivedInvocations.isEmpty)
    }

    // MARK: - pullMeetings

    @Test
    func pullMeetingsReplacesStoredMeetingsWithBackendResponse() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = [Scaffolding.meetingResponse]

        // When

        try await sut.pullMeetings()

        // Then

        #expect(localStore.replaceAllMeetingsWithMeetingsMeetingVoidReceivedInvocations.count == 1)
        #expect(
            localStore.replaceAllMeetingsWithMeetingsMeetingVoidReceivedInvocations.first?.map(\.id)
                == [Scaffolding.meetingID]
        )
    }

    @Test
    func pullMeetingsDoesNothingWhenEndpointIsUnsupported() async throws {
        // Mock

        meetingsAPI.listMeetings_MockError = MeetingsAPIError.unsupportedEndpointForAPIVersion

        // When

        try await sut.pullMeetings()

        // Then

        #expect(localStore.replaceAllMeetingsWithMeetingsMeetingVoidReceivedInvocations.isEmpty)
    }

    @Test
    func pullMeetingsThrowsWhenListingMeetingsFails() async {
        // Mock

        meetingsAPI.listMeetings_MockError = MeetingsAPIError.meetingNotFound

        // When / Then

        await #expect(throws: (any Error).self) {
            try await sut.pullMeetings()
        }
        #expect(localStore.replaceAllMeetingsWithMeetingsMeetingVoidReceivedInvocations.isEmpty)
    }

    @Test
    func pullMeetingsBroadcastsMeetingChange() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = [Scaffolding.meetingResponse]
        var changes = sut.observeMeetingChanges().makeAsyncIterator()

        // When

        try await sut.pullMeetings()

        // Then — the yielded event is buffered by the stream

        #expect(await changes.next() != nil)
    }

    // MARK: - deleteLocalMeeting

    @Test
    func deleteLocalMeetingDeletesMeetingFromLocalStore() async {
        // When

        await sut.deleteLocalMeeting(id: Scaffolding.meetingID)

        // Then

        #expect(localStore.deleteMeetingIdQualifiedIDVoidReceivedInvocations == [Scaffolding.meetingID])
    }

    // MARK: - deleteMeeting

    @Test
    func deleteMeetingDeletesMeetingViaAPIAndFromLocalStore() async throws {
        // Mock

        meetingsAPI.deleteMeetingId_MockMethod = { _ in }

        // When

        try await sut.deleteMeeting(id: Scaffolding.meetingID)

        // Then

        #expect(meetingsAPI.deleteMeetingId_Invocations == [Scaffolding.meetingID])
        #expect(localStore.deleteMeetingIdQualifiedIDVoidReceivedInvocations == [Scaffolding.meetingID])
    }

    @Test
    func deleteMeetingDeletesLocalCopyWhenMeetingIsAlreadyGoneFromBackend() async throws {
        // Mock

        meetingsAPI.deleteMeetingId_MockError = MeetingsAPIError.meetingNotFound

        // When

        try await sut.deleteMeeting(id: Scaffolding.meetingID)

        // Then

        #expect(localStore.deleteMeetingIdQualifiedIDVoidReceivedInvocations == [Scaffolding.meetingID])
    }

    @Test
    func deleteMeetingThrowsAndKeepsLocalCopyWhenDeletingFails() async {
        // Mock

        meetingsAPI.deleteMeetingId_MockError = MeetingsAPIError.accessDenied

        // When / Then

        await #expect(throws: (any Error).self) {
            try await sut.deleteMeeting(id: Scaffolding.meetingID)
        }
        #expect(localStore.deleteMeetingIdQualifiedIDVoidReceivedInvocations.isEmpty)
    }

    // MARK: - observeMeetingChanges

    @Test
    func pullMeetingBroadcastsMeetingChange() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = [Scaffolding.meetingResponse]
        var changes = sut.observeMeetingChanges().makeAsyncIterator()

        // When

        try await sut.pullMeeting(id: Scaffolding.meetingID)

        // Then — the yielded event is buffered by the stream

        #expect(await changes.next() != nil)
    }

    @Test
    func deleteLocalMeetingBroadcastsMeetingChange() async {
        // Mock

        var changes = sut.observeMeetingChanges().makeAsyncIterator()

        // When

        await sut.deleteLocalMeeting(id: Scaffolding.meetingID)

        // Then

        #expect(await changes.next() != nil)
    }

    @Test
    func deleteMeetingBroadcastsMeetingChange() async throws {
        // Mock

        meetingsAPI.deleteMeetingId_MockMethod = { _ in }
        var changes = sut.observeMeetingChanges().makeAsyncIterator()

        // When

        try await sut.deleteMeeting(id: Scaffolding.meetingID)

        // Then

        #expect(await changes.next() != nil)
    }

    @Test
    func participantChangeBroadcastsMeetingChange() async throws {
        // Mock

        let (participantChanges, participantContinuation) = AsyncStream<Void>.makeStream()
        localStore.observeMeetingConversationChangesAsyncStreamVoidReturnValue = participantChanges
        var changes = sut.observeMeetingChanges().makeAsyncIterator()

        // When — a member joins the conversation of a stored meeting

        participantContinuation.yield()

        // Then

        #expect(await changes.next() != nil)
    }

    @Test
    func createMeetingBroadcastsMeetingChange() async throws {
        // Mock

        meetingsAPI.createMeetingParameters_MockValue = Scaffolding.meetingResponse
        var changes = sut.observeMeetingChanges().makeAsyncIterator()

        // When

        _ = try await sut.createMeeting(
            title: Scaffolding.meetingResponse.title,
            startTime: Scaffolding.meetingResponse.startTime,
            endTime: Scaffolding.meetingResponse.endTime,
            recurrence: nil
        )

        // Then

        #expect(await changes.next() != nil)
    }

    // MARK: - fetchMeetings(in:)

    @Test
    func fetchMeetingsRefreshesStoreAndReturnsSortedMeetingsInRange() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = [Scaffolding.meetingResponse]
        localStore.storedMeetingsMeetingReturnValue = [
            Scaffolding.meeting(title: "B", start: Scaffolding.referenceDate.addingTimeInterval(3600)),
            Scaffolding.meeting(title: "A", start: Scaffolding.referenceDate.addingTimeInterval(3600)),
            Scaffolding.meeting(title: "Started", start: Scaffolding.referenceDate.addingTimeInterval(-3600)),
            Scaffolding.meeting(title: "Before range", start: Scaffolding.referenceDate.addingTimeInterval(-7200)),
            Scaffolding.meeting(title: "After range", start: Scaffolding.referenceDate.addingTimeInterval(7200))
        ]

        // When

        let meetings = try await sut.fetchMeetings(
            in: Scaffolding.referenceDate.addingTimeInterval(-3600)
                ..< Scaffolding.referenceDate.addingTimeInterval(7200),
            offset: 0,
            limit: 10
        )

        // Then
        // The range's lower bound is inclusive, so "Started" is returned;
        // the upper bound is exclusive, so "After range" is not.

        #expect(localStore.replaceAllMeetingsWithMeetingsMeetingVoidReceivedInvocations.count == 1)
        #expect(meetings.map(\.title) == ["Started", "A", "B"])
    }

    @Test
    func fetchMeetingsServesStoredMeetingsWhenBackendIsUnreachable() async throws {
        // Mock

        meetingsAPI.listMeetings_MockError = MeetingsAPIError.meetingNotFound
        localStore.storedMeetingsMeetingReturnValue = [
            Scaffolding.meeting(title: "Stored", start: Scaffolding.referenceDate.addingTimeInterval(3600))
        ]

        // When

        let meetings = try await sut.fetchMeetings(
            in: Scaffolding.referenceDate ..< Date.distantFuture,
            offset: 0,
            limit: 10
        )

        // Then

        #expect(meetings.map(\.title) == ["Stored"])
    }

    @Test
    func fetchMeetingsThrowsWhenBackendIsUnreachableAndStoreIsEmpty() async {
        // Mock

        meetingsAPI.listMeetings_MockError = MeetingsAPIError.meetingNotFound
        localStore.storedMeetingsMeetingReturnValue = []

        // When / Then

        await #expect(throws: (any Error).self) {
            _ = try await sut.fetchMeetings(
                in: Scaffolding.referenceDate ..< Date.distantFuture,
                offset: 0,
                limit: 10
            )
        }
    }

    // MARK: - hasUpcomingMeetings

    @Test
    func hasUpcomingMeetingsReturnsTrueWhenAStoredMeetingIsUpcoming() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = []
        localStore.storedMeetingsMeetingReturnValue = [
            Scaffolding.meeting(title: "Upcoming", start: Scaffolding.referenceDate.addingTimeInterval(3600))
        ]

        // When / Then

        let hasUpcoming = try await sut.hasUpcomingMeetings(after: Scaffolding.referenceDate)
        #expect(hasUpcoming)
    }

    // MARK: - createMeeting

    @Test
    func createMeetingCreatesMeetingViaAPIAndStoresIt() async throws {
        // Mock

        meetingsAPI.createMeetingParameters_MockValue = Scaffolding.meetingResponse

        // When

        let meeting = try await sut.createMeeting(
            title: Scaffolding.meetingResponse.title,
            startTime: Scaffolding.meetingResponse.startTime,
            endTime: Scaffolding.meetingResponse.endTime,
            recurrence: nil
        )

        // Then

        #expect(meetingsAPI.createMeetingParameters_Invocations.count == 1)
        #expect(meeting.id == Scaffolding.meetingID)
        #expect(localStore.storeMeetingMeetingMeetingVoidReceivedInvocations.count == 1)
        #expect(localStore.storeMeetingMeetingMeetingVoidReceivedInvocations.first?.id == Scaffolding.meetingID)
    }

    @Test("createMeeting returns the stored copy, which has its participants populated")
    func createMeetingReturnsStoredCopy() async throws {
        // Mock

        meetingsAPI.createMeetingParameters_MockValue = Scaffolding.meetingResponse
        localStore.storedMeetingIdQualifiedIDMeetingReturnValue = Scaffolding.storedMeeting

        // When

        let meeting = try await sut.createMeeting(
            title: Scaffolding.meetingResponse.title,
            startTime: Scaffolding.meetingResponse.startTime,
            endTime: Scaffolding.meetingResponse.endTime,
            recurrence: nil
        )

        // Then

        #expect(localStore.storedMeetingIdQualifiedIDMeetingReceivedId == Scaffolding.meetingID)
        #expect(meeting == Scaffolding.storedMeeting)
        #expect(meeting.conversation?.participants == [Scaffolding.member])
    }

    @Test("createMeeting falls back to the mapped meeting when the store can't provide it")
    func createMeetingFallsBackToMappedMeeting() async throws {
        // Mock — storedMeeting(id:) is not stubbed and returns nil, like right
        // after creation, when the meeting's conversation is not pulled yet.

        meetingsAPI.createMeetingParameters_MockValue = Scaffolding.meetingResponse

        // When

        let meeting = try await sut.createMeeting(
            title: Scaffolding.meetingResponse.title,
            startTime: Scaffolding.meetingResponse.startTime,
            endTime: Scaffolding.meetingResponse.endTime,
            recurrence: nil
        )

        // Then

        #expect(meeting.id == Scaffolding.meetingID)
        #expect(meeting.conversation == nil)
    }

    @Test("pullMeeting returns the stored copy, which has its participants populated")
    func pullMeetingReturnsStoredCopy() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = [Scaffolding.meetingResponse]
        localStore.storedMeetingIdQualifiedIDMeetingReturnValue = Scaffolding.storedMeeting

        // When

        let meeting = try await sut.pullMeeting(id: Scaffolding.meetingID)

        // Then

        #expect(localStore.storedMeetingIdQualifiedIDMeetingReceivedId == Scaffolding.meetingID)
        #expect(meeting == Scaffolding.storedMeeting)
        #expect(meeting?.conversation?.participants == [Scaffolding.member])
    }

    private enum Scaffolding {

        static let referenceDate = Date(timeIntervalSince1970: 500_000)

        static let meetingID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            domain: "example.com"
        )

        static let meetingResponse = MeetingResponse(
            id: meetingID,
            title: "Weekly Sync",
            creatorID: WireNetwork.QualifiedID(id: UUID(), domain: "example.com"),
            startTime: Date(timeIntervalSince1970: 1_000_000),
            endTime: Date(timeIntervalSince1970: 1_003_600),
            conversationID: WireNetwork.QualifiedID(id: UUID(), domain: "example.com"),
            invitedEmails: [],
            isTrial: false,
            createdAt: Date(timeIntervalSince1970: 900_000),
            updatedAt: Date(timeIntervalSince1970: 900_000)
        )

        static let member = MeetingMember(
            qualifiedID: WireNetwork.QualifiedID(id: UUID(), domain: "example.com"),
            name: "Katie Armstrong",
            handle: "katie",
            isSelfUser: false,
            initials: "",
            accentColor: .default,
            avatarImageData: nil
        )

        /// The meeting as the local store provides it,
        /// with its participants populated from the conversation.
        static let storedMeeting = Meeting(
            id: meetingID,
            title: meetingResponse.title,
            start: meetingResponse.startTime,
            end: meetingResponse.endTime,
            recurrence: nil,
            conversation: MeetingConversation(participants: [member]),
            conversationID: meetingResponse.conversationID,
            creatorID: meetingResponse.creatorID
        )

        static func meeting(title: String, start: Date) -> Meeting {
            Meeting(
                id: WireNetwork.QualifiedID(id: UUID(), domain: "example.com"),
                title: title,
                start: start,
                end: start.addingTimeInterval(3600),
                recurrence: nil,
                conversationID: WireNetwork.QualifiedID(id: UUID(), domain: "example.com"),
                creatorID: WireNetwork.QualifiedID(id: UUID(), domain: "example.com")
            )
        }

    }

}
