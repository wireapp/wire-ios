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

class MeetingsAPIV16: MeetingsAPIV15 {

    override var apiVersion: APIVersion {
        .v16
    }

    // MARK: - List meetings

    override func listMeetings() async throws -> [MeetingResponse] {
        let path = "\(pathPrefix)/meetings/list"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: MeetingListResponseV16.self)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Create meeting

    override func createMeeting(parameters: CreateMeetingParameters) async throws -> MeetingResponse {
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let path = "\(pathPrefix)/meetings"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .created, type: MeetingResponseV16.self)
            .failure(code: .forbidden, label: "invalid-op", error: MeetingsAPIError.invalidOperation)
            .failure(code: .unreachable, error: MeetingsAPIError.unreachableBackends)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Update meeting

    override func updateMeeting(
        id: QualifiedID,
        parameters: UpdateMeetingParameters
    ) async throws -> MeetingResponse {
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let path = "\(pathPrefix)/meetings/\(id.domain)/\(id.id.uuidString.lowercased())"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: MeetingResponseV16.self)
            .failure(code: .forbidden, label: "invalid-op", error: MeetingsAPIError.invalidOperation)
            .failure(code: .forbidden, label: "access-denied", error: MeetingsAPIError.accessDenied)
            .failure(code: .notFound, label: "meeting-not-found", error: MeetingsAPIError.meetingNotFound)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Delete meeting

    override func deleteMeeting(id: QualifiedID) async throws {
        let path = "\(pathPrefix)/meetings/\(id.domain)/\(id.id.uuidString.lowercased())"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.delete)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        try ResponseParser()
            .success(code: .ok)
            .failure(code: .forbidden, label: "access-denied", error: MeetingsAPIError.accessDenied)
            .failure(code: .notFound, label: "meeting-not-found", error: MeetingsAPIError.meetingNotFound)
            .parse(code: response.statusCode, data: data)
    }

}
