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

import WireMessagingDomainSupport
@testable import WireMessagingDomain
@testable import WireMessagingUI

final class WireDriveFetchNodeVersionsUseCaseTests {

    private let repository = MockWireDriveNodesRepositoryProtocol()
    private let sut: WireDriveFetchNodeVersionsUseCase

    init() {
        self.sut = WireDriveFetchNodeVersionsUseCase(
            repository: repository
        )
    }

    @Test
    func `It returns a collection of WireDriveNodeVersion`() async throws {
        // given
        repository.getVersionsNodeID_MockValue = WireDriveNodeVersion.mock

        // when
        let result = try await sut.invoke(nodeID: .mockID1)

        // then
        #expect(result == WireDriveNodeVersion.mock)
    }

    @Test
    func `It fails retrieving node versions`() async throws {
        // given
        repository.getVersionsNodeID_MockError = NSError(domain: "any", code: 0)

        // when
        await #expect(throws: WireDriveFetchNodeVersionsUseCase.Failure.unableToRetrieveNodeVersions) {
            // then
            try await sut.invoke(nodeID: .mockID1)
        }
    }

}
