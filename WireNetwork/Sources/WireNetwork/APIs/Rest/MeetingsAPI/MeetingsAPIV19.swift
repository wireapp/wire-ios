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

final class MeetingsAPIV19: MeetingsAPIV18 {

    override var apiVersion: APIVersion {
        .v19
    }

    override func joinMeeting(
        domain: String,
        key: String,
        code: String,
        password: String?
    ) async throws -> MeetingJoinResponse {
        guard let encodedDomain = domain.pathEncoded,
              let encodedKey = key.pathEncoded,
              let encodedCode = code.pathEncoded else {
            throw MeetingsAPIError.failedToGenerateRequest
        }
        let path = "\(pathPrefix)/meeting/\(encodedDomain)/\(encodedKey)/\(encodedCode)/join"
        var builder = try URLRequestBuilder(path: path).withMethod(.post)
        if let password {
            builder = builder.withQueryItem(name: "password", value: password)
        }
        let request = builder.build()
        let (data, response) = try await apiService.executeRequest(request, requiringAccessToken: true)

        return try ResponseParser()
            .success(code: .ok, type: MeetingJoinResponseV19.self)
            .failure(
                code: .forbidden,
                label: "invalid-meeting-password",
                error: MeetingsAPIError.invalidMeetingPassword
            )
            .failure(code: .forbidden, label: "invalid-op", error: MeetingsAPIError.invalidOperation)
            .failure(code: .forbidden, label: "access-denied", error: MeetingsAPIError.accessDenied)
            .failure(code: .forbidden, label: "too-many-members", error: MeetingsAPIError.tooManyMembers)
            .failure(code: .notFound, label: "meeting-not-found", error: MeetingsAPIError.meetingNotFound)
            .parse(code: response.statusCode, data: data)
    }

    override func createMeeting(parameters: CreateMeetingParameters) async throws -> MeetingResponse {
        let body = try JSONEncoder.defaultEncoder.encode(CreateMeetingParametersV19(parameters: parameters))
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

    override func addMeetingInvitations(id: QualifiedID, emails: [String]) async throws {
        let path = "\(pathPrefix)/meetings/\(id.domain)/\(id.id.uuidString.lowercased())/invitations"
        try await sendInvitationRequest(path: path, emails: emails)
    }

    override func removeMeetingInvitations(id: QualifiedID, emails: [String]) async throws {
        let path = "\(pathPrefix)/meetings/\(id.domain)/\(id.id.uuidString.lowercased())/invitations/delete"
        try await sendInvitationRequest(path: path, emails: emails)
    }

    private func sendInvitationRequest(path: String, emails: [String]) async throws {
        let body = try JSONEncoder.defaultEncoder.encode(MeetingInvitationsParameters(emails: emails))
        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        try ResponseParser()
            .success(code: .ok)
            .failure(code: .forbidden, label: "invalid-op", error: MeetingsAPIError.invalidOperation)
            .failure(code: .forbidden, label: "access-denied", error: MeetingsAPIError.accessDenied)
            .failure(code: .notFound, label: "meeting-not-found", error: MeetingsAPIError.meetingNotFound)
            .parse(code: response.statusCode, data: data)
    }

}

private extension String {
    var pathEncoded: String? {
        addingPercentEncoding(withAllowedCharacters: .urlPathSegmentCharacters)
    }
}

private extension CharacterSet {
    static let urlPathSegmentCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
    )
}

private struct MeetingJoinResponseV19: Decodable, ToAPIModelConvertible {
    let meeting: MeetingResponseV16
    let conversation: ConversationV16

    private enum CodingKeys: String, CodingKey {
        case conversation
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.meeting = try MeetingResponseV16(from: decoder)
        self.conversation = try container.decode(ConversationV16.self, forKey: .conversation)
    }

    func toAPIModel() -> MeetingJoinResponse {
        MeetingJoinResponse(meeting: meeting.toAPIModel(), conversation: conversation.toAPIModel())
    }
}

private struct MeetingInvitationsParameters: Encodable {
    let emails: [String]
}

private struct CreateMeetingParametersV19: Encodable {
    let parameters: CreateMeetingParameters

    private enum CodingKeys: String, CodingKey {
        case type
        case password
    }

    func encode(to encoder: any Encoder) throws {
        try parameters.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parameters.type, forKey: .type)
        try container.encodeIfPresent(parameters.password, forKey: .password)
    }

}
