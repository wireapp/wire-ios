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

import XCTest

@testable import WireNetwork
@testable import WireNetworkSupport

final class MeetingsAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any MeetingsAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = MeetingsAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func testListMeetings_Request_Generation_V16() async throws {
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, "MeetingListResponse")])

        try await apiSnapshotHelper.verifyRequest(for: [.v16], apiService: apiService) { sut in
            _ = try await sut.listMeetings()
        }
    }

    func testCreateMeeting_Request_Generation_V16() async throws {
        let apiVersions = APIVersion.v16.andNextVersions
        let apiService = MockAPIServiceProtocol.withResponses(
            .init(repeating: (.created, "MeetingResponse"), count: apiVersions.count)
        )

        try await apiSnapshotHelper.verifyRequest(for: apiVersions, apiService: apiService) { sut in
            _ = try await sut.createMeeting(parameters: Scaffolding.createParameters)
        }
    }

    func testUpdateMeeting_Request_Generation_V16() async throws {
        let apiVersions = APIVersion.v16.andNextVersions
        let apiService = MockAPIServiceProtocol.withResponses(
            .init(repeating: (.ok, "MeetingResponse"), count: apiVersions.count)
        )

        try await apiSnapshotHelper.verifyRequest(for: apiVersions, apiService: apiService) { sut in
            _ = try await sut.updateMeeting(id: Scaffolding.meetingID, parameters: Scaffolding.updateParameters)
        }
    }

    func testDeleteMeeting_Request_Generation_V16() async throws {
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, nil)])

        try await apiSnapshotHelper.verifyRequest(for: [.v16], apiService: apiService) { sut in
            try await sut.deleteMeeting(id: Scaffolding.meetingID)
        }
    }

    // MARK: - createMeeting V16+

    func testCreateMeeting_SuccessResponse_201_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([(.created, "MeetingResponse")])
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When
        let result = try await sut.createMeeting(parameters: Scaffolding.createParameters)

        // Then
        XCTAssertEqual(result.id, Scaffolding.meetingID)
        XCTAssertEqual(result.title, "Engineering Sync")
    }

    func testCreateMeeting_V19_SendsTypeAndPasswordAndReadsReturnedLink() async throws {
        let resource = try MockJSONPayloadResource(name: "MeetingResponse")
        var responseJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: resource.jsonData) as? [String: Any])
        let link = "https://account.wire.com/meeting-join/?key=returned-key&code=returned-code&domain=wire.com"
        responseJSON.removeValue(forKey: "trial")
        responseJSON["type"] = "immediate"
        responseJSON["link"] = link
        let responseData = try JSONSerialization.data(withJSONObject: responseJSON)
        let apiService = MockAPIServiceProtocol()
        apiService.executeRequestRequiringAccessToken_MockMethod = { request, _ in
            let (_, response) = try request.mockResponse(statusCode: .created)
            return (responseData, response)
        }
        let sut = APIVersion.v19.buildAPI(apiService: apiService)
        let parameters = CreateMeetingParameters(
            title: "Engineering Sync",
            startTime: Scaffolding.startTime,
            endTime: Scaffolding.endTime,
            timeZoneIdentifier: "America/New_York",
            type: .immediate,
            password: "meeting-password",
            invitedEmails: Scaffolding.invitedEmails
        )

        let result = try await sut.createMeeting(parameters: parameters)

        XCTAssertEqual(apiService.executeRequestRequiringAccessToken_Invocations.count, 1)
        let body = try XCTUnwrap(apiService.executeRequestRequiringAccessToken_Invocations.first?.request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["type"] as? String, "immediate")
        XCTAssertEqual(json["password"] as? String, "meeting-password")
        XCTAssertEqual(json["invited_emails"] as? [String], Scaffolding.invitedEmails)
        XCTAssertEqual(result.link?.absoluteString, link)
    }

    func testCreateMeeting_RejectsPassword_V16_To_V18() async {
        for version in [APIVersion.v16, .v17, .v18] {
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)
            let parameters = CreateMeetingParameters(
                title: "Engineering Sync",
                startTime: Scaffolding.startTime,
                endTime: Scaffolding.endTime,
                timeZoneIdentifier: "America/New_York",
                password: "meeting-password"
            )

            await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
                _ = try await sut.createMeeting(parameters: parameters)
            }

            XCTAssertTrue(apiService.executeRequestRequiringAccessToken_Invocations.isEmpty)
        }
    }

    func testCreateMeeting_ThrowsUnsupportedEndpoint_V0_to_V15() async throws {
        let unsupportedVersions = APIVersion.allCasesUpTo(.v16)

        for version in unsupportedVersions {
            // Given
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)

            // When / Then
            await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
                _ = try await sut.createMeeting(parameters: Scaffolding.createParameters)
            }
        }
    }

    func testCreateMeeting_ThrowsInvalidOperation_403_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "invalid-op"
        )
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.invalidOperation) {
            _ = try await sut.createMeeting(parameters: Scaffolding.createParameters)
        }
    }

    func testCreateMeeting_ThrowsUnreachableBackends_533_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(statusCode: .unreachable)
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.unreachableBackends) {
            _ = try await sut.createMeeting(parameters: Scaffolding.createParameters)
        }
    }

    // MARK: - updateMeeting V16+

    func testUpdateMeeting_EncodesRecurrenceChanges_TC_11994() async throws {
        // Check unchanged, cleared and replaced recurrence through each supported API version.
        for version in APIVersion.v16.andNextVersions {
            let parameters = [
                UpdateMeetingParameters(title: "New title"),
                UpdateMeetingParameters(recurrence: .some(nil)),
                UpdateMeetingParameters(recurrence: MeetingRecurrence(frequency: .weekly, interval: 2, until: nil))
            ]
            let apiService = MockAPIServiceProtocol.withResponses(
                .init(repeating: (.ok, "MeetingResponse"), count: parameters.count)
            )
            let sut = version.buildAPI(apiService: apiService)
            for parameter in parameters {
                _ = try await sut.updateMeeting(id: Scaffolding.meetingID, parameters: parameter)
            }
            let payloads = try apiService.executeRequestRequiringAccessToken_Invocations.map {
                try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap($0.request.httpBody)) as? [String: Any])
            }
            XCTAssertNil(payloads[0]["recurrence"])
            XCTAssertTrue(payloads[1]["recurrence"] is NSNull)
            let recurrence = try XCTUnwrap(payloads[2]["recurrence"] as? [String: Any])
            XCTAssertEqual(recurrence["frequency"] as? String, "weekly")
            XCTAssertEqual(recurrence["interval"] as? Int, 2)
        }
    }

    func testUpdateMeeting_SuccessResponse_200_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, "MeetingResponse")])
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When
        let result = try await sut.updateMeeting(
            id: Scaffolding.meetingID,
            parameters: Scaffolding.updateParameters
        )

        // Then
        XCTAssertEqual(result.id, Scaffolding.meetingID)
        XCTAssertEqual(result.title, "Engineering Sync")
    }

    func testUpdateMeeting_ThrowsUnsupportedEndpoint_V0_to_V15() async throws {
        let unsupportedVersions = APIVersion.allCasesUpTo(.v16)

        for version in unsupportedVersions {
            // Given
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)

            // When / Then
            await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
                _ = try await sut.updateMeeting(
                    id: Scaffolding.meetingID,
                    parameters: Scaffolding.updateParameters
                )
            }
        }
    }

    func testUpdateMeeting_ThrowsInvalidOperation_403_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "invalid-op"
        )
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.invalidOperation) {
            _ = try await sut.updateMeeting(id: Scaffolding.meetingID, parameters: Scaffolding.updateParameters)
        }
    }

    func testUpdateMeeting_ThrowsAccessDenied_403_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "access-denied"
        )
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.accessDenied) {
            _ = try await sut.updateMeeting(id: Scaffolding.meetingID, parameters: Scaffolding.updateParameters)
        }
    }

    func testUpdateMeeting_ThrowsMeetingNotFound_404_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "meeting-not-found"
        )
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.meetingNotFound) {
            _ = try await sut.updateMeeting(id: Scaffolding.meetingID, parameters: Scaffolding.updateParameters)
        }
    }

    // MARK: - listMeetings V16

    func testListMeetings_SuccessResponse_200_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, "MeetingListResponse")])
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When
        let result = try await sut.listMeetings()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, Scaffolding.meetingID)
        XCTAssertEqual(result[0].title, "Engineering Sync")
        XCTAssertEqual(result[1].title, "Design Review")
    }

    func testListMeetings_ThrowsUnsupportedEndpoint_V0_to_V15() async throws {
        let unsupportedVersions = APIVersion.allCasesUpTo(.v16)

        for version in unsupportedVersions {
            // Given
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)

            // When / Then
            await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
                _ = try await sut.listMeetings()
            }
        }
    }

    // MARK: - deleteMeeting V16

    func testDeleteMeeting_SuccessResponse_200_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, nil)])
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then - no throw expected
        try await sut.deleteMeeting(id: Scaffolding.meetingID)
    }

    func testDeleteMeeting_ThrowsUnsupportedEndpoint_V0_to_V15() async throws {
        let unsupportedVersions = APIVersion.allCasesUpTo(.v16)

        for version in unsupportedVersions {
            // Given
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)

            // When / Then
            await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
                try await sut.deleteMeeting(id: Scaffolding.meetingID)
            }
        }
    }

    func testDeleteMeeting_ThrowsInvalidOperation_403_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "invalid-op"
        )
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.invalidOperation) {
            try await sut.deleteMeeting(id: Scaffolding.meetingID)
        }
    }

    func testDeleteMeeting_ThrowsAccessDenied_403_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "access-denied"
        )
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.accessDenied) {
            try await sut.deleteMeeting(id: Scaffolding.meetingID)
        }
    }

    func testDeleteMeeting_ThrowsMeetingNotFound_404_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "meeting-not-found"
        )
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.meetingNotFound) {
            try await sut.deleteMeeting(id: Scaffolding.meetingID)
        }
    }

    // MARK: - Email invitations

    func testMeetingInvitations_V19_SendExpectedRequests() async throws {
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, nil), (.ok, nil)])
        let sut = APIVersion.v19.buildAPI(apiService: apiService)

        try await sut.addMeetingInvitations(id: Scaffolding.meetingID, emails: Scaffolding.invitedEmails)
        try await sut.removeMeetingInvitations(id: Scaffolding.meetingID, emails: Scaffolding.invitedEmails)

        let invocations = apiService.executeRequestRequiringAccessToken_Invocations
        XCTAssertEqual(invocations.count, 2)
        for (invocation, suffix) in zip(invocations, ["", "/delete"]) {
            XCTAssertEqual(
                invocation.request.url?.absoluteString,
                "/v19/meetings/wire.com/9c2e5e1a-1234-5678-abcd-0123456789ab/invitations\(suffix)"
            )
            XCTAssertEqual(invocation.request.httpMethod, "POST")
            XCTAssertEqual(invocation.request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertTrue(invocation.requiringAccessToken)
            let body = try XCTUnwrap(invocation.request.httpBody)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: [String]])
            XCTAssertEqual(json, ["emails": Scaffolding.invitedEmails])
        }
    }

    func testRefreshMeetingLink_V19_SendsPasswordAndReadsMeeting() async throws {
        let resource = try MockJSONPayloadResource(name: "MeetingResponse")
        var responseJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: resource.jsonData) as? [String: Any])
        let link = "https://account.wire.com/meeting-join/?key=rotated-key&code=rotated-code&domain=wire.com"
        responseJSON.removeValue(forKey: "trial")
        responseJSON["type"] = "scheduled"
        responseJSON["link"] = link
        responseJSON["has_password"] = true
        let responseData = try JSONSerialization.data(withJSONObject: responseJSON)
        let apiService = MockAPIServiceProtocol()
        apiService.executeRequestRequiringAccessToken_MockMethod = { request, _ in
            let (_, response) = try request.mockResponse(statusCode: .ok)
            return (responseData, response)
        }
        let sut = APIVersion.v19.buildAPI(apiService: apiService)

        let result = try await sut.refreshMeetingLink(id: Scaffolding.meetingID, password: "new-password")

        let invocation = try XCTUnwrap(apiService.executeRequestRequiringAccessToken_Invocations.first)
        XCTAssertEqual(
            invocation.request.url?.absoluteString,
            "/v19/meetings/wire.com/9c2e5e1a-1234-5678-abcd-0123456789ab/link/refresh"
        )
        XCTAssertEqual(invocation.request.httpMethod, "POST")
        XCTAssertTrue(invocation.requiringAccessToken)
        let body = try XCTUnwrap(invocation.request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["password"] as? String, "new-password")
        XCTAssertEqual(Set(json.keys), ["password"])
        XCTAssertEqual(result.link?.absoluteString, link)
        XCTAssertEqual(result.hasPassword, true)
    }

    func testRefreshMeetingLink_OmitsNilPassword() async throws {
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, "MeetingResponse")])
        let sut = APIVersion.v19.buildAPI(apiService: apiService)

        _ = try await sut.refreshMeetingLink(id: Scaffolding.meetingID, password: nil)

        let body = try XCTUnwrap(apiService.executeRequestRequiringAccessToken_Invocations.first?.request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertTrue(json.isEmpty)
    }

    func testRefreshMeetingLink_UnsupportedInV0AndV18() async {
        for version in [APIVersion.v0, .v18] {
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)

            await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
                _ = try await sut.refreshMeetingLink(id: Scaffolding.meetingID, password: nil)
            }
            XCTAssertTrue(apiService.executeRequestRequiringAccessToken_Invocations.isEmpty)
        }
    }

    func testMeetingInvitations_V18_ThrowsUnsupportedEndpointWithoutRequest() async {
        let apiService = MockAPIServiceProtocol()
        let sut = APIVersion.v18.buildAPI(apiService: apiService)

        await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
            try await sut.addMeetingInvitations(id: Scaffolding.meetingID, emails: Scaffolding.invitedEmails)
        }
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
            try await sut.removeMeetingInvitations(id: Scaffolding.meetingID, emails: Scaffolding.invitedEmails)
        }

        XCTAssertTrue(apiService.executeRequestRequiringAccessToken_Invocations.isEmpty)
    }

    func testAddMeetingInvitations_V19_ThrowsAccessDenied() async {
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "access-denied")
        let sut = APIVersion.v19.buildAPI(apiService: apiService)

        await XCTAssertThrowsErrorAsync(MeetingsAPIError.accessDenied) {
            try await sut.addMeetingInvitations(id: Scaffolding.meetingID, emails: Scaffolding.invitedEmails)
        }
    }

    func testRemoveMeetingInvitations_V19_ThrowsMeetingNotFound() async {
        let apiService = MockAPIServiceProtocol.withError(statusCode: .notFound, label: "meeting-not-found")
        let sut = APIVersion.v19.buildAPI(apiService: apiService)

        await XCTAssertThrowsErrorAsync(MeetingsAPIError.meetingNotFound) {
            try await sut.removeMeetingInvitations(id: Scaffolding.meetingID, emails: Scaffolding.invitedEmails)
        }
    }

    // MARK: -

    enum Scaffolding {
        static let invitedEmails = ["guest@example.com", "member@wire.com"]
        static let meetingID = QualifiedID(
            id: UUID(uuidString: "9c2e5e1a-1234-5678-abcd-0123456789ab")!,
            domain: "wire.com"
        )
        static let startTime = try! Date.ISO8601FormatStyle().parse("2025-06-25T10:00:00Z")
        static let endTime = try! Date.ISO8601FormatStyle().parse("2025-06-25T11:00:00Z")
        static let createParameters = CreateMeetingParameters(
            title: "Engineering Sync",
            startTime: startTime,
            endTime: endTime,
            timeZoneIdentifier: "America/New_York"
        )
        static let updateParameters = UpdateMeetingParameters(
            title: "Engineering Sync (Updated)",
            startTime: startTime,
            endTime: endTime
        )
    }

}

private extension APIVersion {
    func buildAPI(apiService: any APIServiceProtocol) -> any MeetingsAPI {
        let builder = MeetingsAPIBuilder(apiService: apiService)
        return builder.makeAPI(for: self)
    }
}
