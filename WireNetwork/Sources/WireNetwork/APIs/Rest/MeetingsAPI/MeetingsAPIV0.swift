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

class MeetingsAPIV0: MeetingsAPI, VersionedAPI {

    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    var apiVersion: APIVersion {
        .v0
    }

    // MARK: - List meetings

    func listMeetings() async throws -> [MeetingResponse] {
        throw MeetingsAPIError.unsupportedEndpointForAPIVersion
    }

    // MARK: - Get meeting

    func getMeeting(id: QualifiedID) async throws -> MeetingResponse {
        throw MeetingsAPIError.unsupportedEndpointForAPIVersion
    }

    // MARK: - Create meeting

    func createMeeting(parameters: CreateMeetingParameters) async throws -> MeetingResponse {
        throw MeetingsAPIError.unsupportedEndpointForAPIVersion
    }

    // MARK: - Update meeting

    func updateMeeting(id: QualifiedID, parameters: UpdateMeetingParameters) async throws -> MeetingResponse {
        throw MeetingsAPIError.unsupportedEndpointForAPIVersion
    }

    // MARK: - Delete meeting

    func deleteMeeting(id: QualifiedID) async throws {
        throw MeetingsAPIError.unsupportedEndpointForAPIVersion
    }

}
