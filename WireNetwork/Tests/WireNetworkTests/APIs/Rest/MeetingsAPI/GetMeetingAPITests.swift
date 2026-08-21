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
import XCTest

@testable import WireNetwork
@testable import WireNetworkSupport

final class GetMeetingAPITests: XCTestCase {

    func testGetMeeting_V16_SendsExpectedRequestAndDecodesResponse() async throws {
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, "MeetingResponse")])
        let sut = makeAPI(version: .v16, apiService: apiService)

        let response = try await sut.getMeeting(id: meetingID)

        XCTAssertEqual(response.id, meetingID)
        XCTAssertEqual(apiService.executeRequestRequiringAccessToken_Invocations.count, 1)

        let invocation = try XCTUnwrap(
            apiService.executeRequestRequiringAccessToken_Invocations.first
        )
        XCTAssertEqual(
            invocation.request.url?.absoluteString,
            "/v16/meetings/wire.com/9c2e5e1a-1234-5678-abcd-0123456789ab"
        )
        XCTAssertEqual(invocation.request.httpMethod, "GET")
        XCTAssertTrue(invocation.requiringAccessToken)
    }

    func testGetMeeting_V17_DecodesResponseWithoutTrial() async throws {
        let resource = try MockJSONPayloadResource(name: "MeetingResponse")
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: resource.jsonData) as? [String: Any]
        )
        json.removeValue(forKey: "trial")
        let responseData = try JSONSerialization.data(withJSONObject: json)

        let apiService = MockAPIServiceProtocol()
        apiService.executeRequestRequiringAccessToken_MockMethod = { request, _ in
            let (_, response) = try request.mockResponse(statusCode: .ok)
            return (responseData, response)
        }
        let sut = makeAPI(version: .v17, apiService: apiService)

        let response = try await sut.getMeeting(id: meetingID)

        XCTAssertEqual(response.id, meetingID)
        XCTAssertFalse(response.isTrial)
    }

    func testGetMeeting_ThrowsUnsupportedEndpoint_V0_To_V15() async {
        for version in APIVersion.allCasesUpTo(.v16) {
            let sut = makeAPI(
                version: version,
                apiService: MockAPIServiceProtocol()
            )

            await XCTAssertThrowsErrorAsync(
                MeetingsAPIError.unsupportedEndpointForAPIVersion
            ) {
                try await sut.getMeeting(id: self.meetingID)
            }
        }
    }

    func testGetMeeting_ThrowsMeetingNotFound_V16() async {
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "meeting-not-found"
        )
        let sut = makeAPI(version: .v16, apiService: apiService)

        await XCTAssertThrowsErrorAsync(MeetingsAPIError.meetingNotFound) {
            try await sut.getMeeting(id: self.meetingID)
        }
    }

    private var meetingID: QualifiedID {
        QualifiedID(
            id: UUID(uuidString: "9c2e5e1a-1234-5678-abcd-0123456789ab")!,
            domain: "wire.com"
        )
    }

    private func makeAPI(
        version: APIVersion,
        apiService: any APIServiceProtocol
    ) -> any MeetingsAPI {
        MeetingsAPIBuilder(apiService: apiService).makeAPI(for: version)
    }

}
