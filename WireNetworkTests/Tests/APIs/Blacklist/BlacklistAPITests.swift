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
import WireFoundationSupport
@testable import WireNetwork
@testable import WireNetworkSupport

struct BlacklistAPITests {

    private let mockDateProvider: CurrentDateProvidingMock

    init() throws {
        self.mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-04-09T12:34:56Z")
    }

    @Test("Generate request")
    func generateRequest() async throws {
        // Then
        try await RequestSnapshotter(
            baseURL: URL(string: "https://www.blacklist.com")!,
            currentDateProvider: mockDateProvider
        ).verifyRequest { _, networkService in
            // Given
            let sut = BlacklistAPIBuilder(networkService: networkService).makeAPI()
            // When
            _ = try? await sut.getBlacklist()
        }
    }

    @Test("Parse response")
    func parseResponse() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "Blacklist")
        ])
        let sut = BlacklistAPIBuilder(networkService: networkService).makeAPI()

        // When
        let blacklist = try await sut.getBlacklist()

        // Then
        #expect(blacklist.minimumLegalBuildNumber == "12345")
        #expect(blacklist.illegalBuildNumbers == ["1111", "2222", "3333"])
    }

}
