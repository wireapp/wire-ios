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

public import Foundation
public import WireCallingDomain
public import WireFoundation
public import WireNetwork

/// The single implementation of `WireCallingDomain.MeetingRepositoryProtocol`.
///
/// The repository bridges between the backend API (`MeetingResponse`) and the
/// meeting domain model (`Meeting`), persisting meetings via the local store.
public final class MeetingRepository: MeetingRepositoryProtocol {

    // MARK: - Properties

    private let meetingsAPI: any MeetingsAPI
    private let localStore: any MeetingLocalStoreProtocol
    private let changeBroadcaster = AsyncBroadcaster()

    // MARK: - Object lifecycle

    public init(
        meetingsAPI: any MeetingsAPI,
        localStore: any MeetingLocalStoreProtocol
    ) {
        self.meetingsAPI = meetingsAPI
        self.localStore = localStore
    }

    // MARK: - Public

    public func fetchMeetingsStarting(after date: Date, offset: Int, limit: Int) async throws -> [Meeting] {
        try await refreshStoredMeetings()

        let allFuture = await localStore.storedMeetings()
            .filter { $0.start > date }
            .sorted {
                if $0.start != $1.start {
                    $0.start < $1.start
                } else {
                    $0.title < $1.title
                }
            }
        let start = min(offset, allFuture.count)
        let end = min(offset + limit, allFuture.count)
        return Array(allFuture[start ..< end])
    }

    public func observeMeetingChanges() -> AsyncStream<Void> {
        changeBroadcaster.makeStream()
    }

    public func hasUpcomingMeetings(after date: Date) async throws -> Bool {
        try await refreshStoredMeetings()

        return await localStore.storedMeetings().contains { $0.start > date }
    }

    public func createMeeting(
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: WireCallingDomain.MeetingRecurrence?
    ) async throws -> Meeting {
        let response = try await meetingsAPI.createMeeting(
            parameters: CreateMeetingParameters(
                title: title,
                startTime: startTime,
                endTime: endTime,
                recurrence: recurrence?.toNetworkRecurrence()
            )
        )
        let meeting = response.toDomainMeeting()
        await localStore.storeMeeting(meeting)
        changeBroadcaster.broadcast()
        return meeting
    }

    public func pullMeeting(id: QualifiedID) async throws {
        // There is no endpoint to fetch a single meeting,
        // so refetch the list to get the details.
        let meetings = try await meetingsAPI.listMeetings()

        if let meeting = meetings.first(where: { $0.id == id }) {
            await localStore.storeMeeting(meeting.toDomainMeeting())
        } else {
            // The meeting no longer exists on the backend.
            await localStore.deleteMeeting(id: id)
        }
        changeBroadcaster.broadcast()
    }

    public func deleteLocalMeeting(id: QualifiedID) async {
        await localStore.deleteMeeting(id: id)
        changeBroadcaster.broadcast()
    }

    // MARK: - Private

    /// Refreshes the local store with the latest snapshot of meetings from the backend.
    /// When the backend is unreachable, previously stored meetings are kept and served;
    /// the error is only rethrown if there are no stored meetings to fall back to.
    private func refreshStoredMeetings() async throws {
        do {
            let meetings = try await meetingsAPI.listMeetings().map { $0.toDomainMeeting() }
            await localStore.replaceAllMeetings(with: meetings)
        } catch {
            guard await !localStore.storedMeetings().isEmpty else { throw error }
        }
    }

}

// MARK: - Mapping

private extension MeetingResponse {

    func toDomainMeeting() -> Meeting {
        Meeting(
            id: id,
            title: title,
            start: startTime,
            end: endTime,
            recurrence: recurrence?.toDomainRecurrence(),
            members: [],
            conversationID: conversationID,
            creatorID: creatorID
        )
    }

}

private extension WireNetwork.MeetingRecurrence {

    func toDomainRecurrence() -> WireCallingDomain.MeetingRecurrence {
        let domainFrequency: WireCallingDomain.MeetingRecurrence.Frequency = switch frequency {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
        return WireCallingDomain.MeetingRecurrence(
            frequency: domainFrequency,
            interval: interval ?? 1,
            until: until
        )
    }

}

private extension WireCallingDomain.MeetingRecurrence {

    func toNetworkRecurrence() -> WireNetwork.MeetingRecurrence {
        let networkFrequency: MeetingFrequency = switch frequency {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
        return WireNetwork.MeetingRecurrence(
            frequency: networkFrequency,
            interval: interval,
            until: until
        )
    }

}
