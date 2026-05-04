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

import WireMessagingDomain
import WireMessagingDomainSupport
import XCTest

@MainActor
final class ChannelHistoryUseCaseTests: XCTestCase {

    lazy var repo = MockChannelRepositoryProtocol()

    func testUpdateHistory_callsRepo() async throws {
        // Given

        let useCase = ChannelHistoryUseCase(
            updateChannelHistoryDepthUseCase: UpdateChannelHistoryDepthUseCase(repository: repo),
            fetchIsEnterpriseUserUseCase: FetchIsEnterpriseUserUseCase(repository: repo)
        )
        repo.updateHistoryDepth_MockMethod = { _ in }

        // When

        _ = try await useCase.updateHistoryDepth(
            channelHistoryOption: .oneDay,
            channelHistoryOptionCustom: .init()
        )

        // Then

        XCTAssertEqual(repo.updateHistoryDepth_Invocations.count, 1)

    }

    func testFetchConferenceCallingFeatureConfig_callsRepo() async throws {
        // Given

        let useCase = ChannelHistoryUseCase(
            updateChannelHistoryDepthUseCase: UpdateChannelHistoryDepthUseCase(repository: repo),
            fetchIsEnterpriseUserUseCase: FetchIsEnterpriseUserUseCase(repository: repo)
        )
        repo.isConferenceCallingFeatureEnabled_MockValue = true

        // When

        _ = try await useCase.isEnterpriseUser()

        // Then

        XCTAssertEqual(repo.isConferenceCallingFeatureEnabled_Invocations.count, 1)

    }
}
