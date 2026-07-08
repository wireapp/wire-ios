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
import WireNetwork

public final class MeetingRepository: MeetingRepositoryProtocol {

    // MARK: - Properties

    private let meetingsAPI: any MeetingsAPI
    private let localStore: any MeetingLocalStoreProtocol

    // MARK: - Object lifecycle

    public init(
        meetingsAPI: any MeetingsAPI,
        localStore: any MeetingLocalStoreProtocol
    ) {
        self.meetingsAPI = meetingsAPI
        self.localStore = localStore
    }

    // MARK: - Public

    public func pullMeeting(id: WireNetwork.QualifiedID) async throws {
        // There is no endpoint to fetch a single meeting,
        // so refetch the list to get the details.
        let meetings = try await meetingsAPI.listMeetings()

        if let meeting = meetings.first(where: { $0.id == id }) {
            await localStore.storeMeeting(meeting)
        } else {
            // The meeting no longer exists on the backend.
            await localStore.deleteMeeting(
                id: id.id,
                domain: id.domain
            )
        }
    }

    public func deleteLocalMeeting(id: UUID, domain: String) async {
        await localStore.deleteMeeting(
            id: id,
            domain: domain
        )
    }

}
