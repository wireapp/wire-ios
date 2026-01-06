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
import WireMessagingDomain

@testable import WireMessagingData
@testable import WireMessagingDomainSupport

struct ObserveDraftsUseCaseTests {

    @Test
    func invoke() async throws {
        // Given
        let draftsRepository = MockDraftsRepositoryProtocol()
        let sut = ObserveDraftsUseCase(cellName: "cell-name", draftRepository: draftsRepository)
        let (stream, continuation) = AsyncStream.makeStream(of: [WireCellsDraft].self)
        draftsRepository.draftsFor_MockValue = stream

        // When
        let output = await sut.invoke()

        let a = WireCellsDraft.fixture()
        let b = WireCellsDraft.fixture()
        let c = WireCellsDraft.fixture()

        continuation.yield([a, b])
        continuation.yield([b, c])
        continuation.finish()

        // Then
        var result: [[WireCellsDraft]] = []
        for await drafts in output {
            result.append(drafts)
        }

        #expect(draftsRepository.draftsFor_Invocations == ["cell-name"])
        #expect(result == [[a, b], [b, c]])
    }

}
