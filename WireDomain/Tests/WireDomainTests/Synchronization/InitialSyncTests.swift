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

import Combine
import XCTest
@testable import WireDomain
@testable import WireDomainSupport

final class InitialSyncTests: XCTestCase {

    private var sut: InitialSync!
    private var pullLastUpdateEventIDSync: MockPullLastUpdateEventIDSyncProtocol!
    private var pullResourcesSync: MockPullResourcesSyncProtocol!
    private var pushSupportedProtocolsUseCase: MockPushSupportedProtocolsUseCaseProtocol!
    private var oneOnOneResolver: MockOneOnOneResolverProtocol!
    private var syncStateSubject: CurrentValueSubject<SyncState, Never>!

    override func setUp() async throws {
        pullLastUpdateEventIDSync = MockPullLastUpdateEventIDSyncProtocol()
        pullResourcesSync = MockPullResourcesSyncProtocol()
        pushSupportedProtocolsUseCase = MockPushSupportedProtocolsUseCaseProtocol()
        oneOnOneResolver = MockOneOnOneResolverProtocol()
        syncStateSubject = CurrentValueSubject(.idle)
        sut = InitialSync(
            pullLastUpdateEventIDSync: pullLastUpdateEventIDSync,
            pullResourcesSync: pullResourcesSync,
            pushSupportedProtocolsUseCase: pushSupportedProtocolsUseCase,
            oneOnOneResolver: oneOnOneResolver,
            syncStateSubject: syncStateSubject
        )
    }

    override func tearDown() async throws {
        pullLastUpdateEventIDSync = nil
        pullResourcesSync = nil
        pushSupportedProtocolsUseCase = nil
        oneOnOneResolver = nil
        syncStateSubject = nil
        sut = nil
    }

    func testPerform_WithoutSkippingLastEventID_Success() async throws {
        // Mock
        pullLastUpdateEventIDSync.pull_MockMethod = {}
        pullResourcesSync.pull_MockMethod = {}
        pushSupportedProtocolsUseCase.invoke_MockMethod = {}
        oneOnOneResolver.resolveAllOneOnOneConversations_MockMethod = {}

        // When
        try await sut.perform(skipPullingLastUpdateEventID: false)

        // Then
        XCTAssertEqual(pullLastUpdateEventIDSync.pull_Invocations.count, 1)
        XCTAssertEqual(pullResourcesSync.pull_Invocations.count, 1)
        XCTAssertEqual(pushSupportedProtocolsUseCase.invoke_Invocations.count, 1)
        XCTAssertEqual(oneOnOneResolver.resolveAllOneOnOneConversations_Invocations.count, 1)
    }

    func testPerform_SkippingLastEventID_Success() async throws {
        // Mock
        pullLastUpdateEventIDSync.pull_MockMethod = {}
        pullResourcesSync.pull_MockMethod = {}
        pushSupportedProtocolsUseCase.invoke_MockMethod = {}
        oneOnOneResolver.resolveAllOneOnOneConversations_MockMethod = {}

        // When
        try await sut.perform(skipPullingLastUpdateEventID: true)

        // Then
        XCTAssertEqual(pullLastUpdateEventIDSync.pull_Invocations.count, 0)
        XCTAssertEqual(pullResourcesSync.pull_Invocations.count, 1)
        XCTAssertEqual(pushSupportedProtocolsUseCase.invoke_Invocations.count, 1)
        XCTAssertEqual(oneOnOneResolver.resolveAllOneOnOneConversations_Invocations.count, 1)
    }

}
