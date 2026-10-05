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

final class MeetingsTestHelper {

    private let networkStack: NetworkStack
    let api: any MeetingsAPI

    init(user: UserInfo) async throws {
        let userHelper = UserHelper.default
        let authenticationManager = MockAuthManager()
        authenticationManager.accessToken = try await userHelper.fetchAccessToken(
            email: user.email,
            password: user.password
        )

        let networkStack = NetworkStack(
            backendEnvironment: userHelper.backend.environment,
            minTLSVersion: .v1_2,
            cookieEncryptionKey: Data(),
            authenticationManager: authenticationManager
        )
        self.networkStack = networkStack
        self.api = MeetingsAPIBuilder(apiService: self.networkStack.apiService)
            .makeAPI(for: userHelper.apiVersion)
    }

    func create(
        title: String,
        start: Date,
        duration: TimeInterval = 1800,
        recurrence: MeetingRecurrence? = nil
    ) async throws -> MeetingResponse {
        try await api.createMeeting(parameters: CreateMeetingParameters(
            title: title,
            startTime: start,
            endTime: start.addingTimeInterval(duration),
            timeZoneIdentifier: TimeZone.current.identifier,
            recurrence: recurrence
        ))
    }

    func update(
        meeting: MeetingResponse,
        title: String? = nil,
        start: Date? = nil
    ) async throws -> MeetingResponse {
        let duration = meeting.endTime.timeIntervalSince(meeting.startTime)
        return try await api.updateMeeting(
            id: meeting.id,
            parameters: UpdateMeetingParameters(
                title: title,
                startTime: start,
                endTime: start?.addingTimeInterval(duration),
                recurrence: meeting.recurrence,
                timeZoneIdentifier: meeting.timeZoneIdentifier
            )
        )
    }

    func list() async throws -> [MeetingResponse] {
        try await api.listMeetings()
    }

    func delete(_ meeting: MeetingResponse) async throws {
        try await api.deleteMeeting(id: meeting.id)
    }
}
