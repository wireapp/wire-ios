//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireDataModelSupport
import WireSyncEngineSupport
import XCTest
@testable import WireSyncEngine

final class ResolveOneOnOneConversationsUseCaseTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        mockSupportedProtocolService = MockSupportedProtocolsServiceInterface()
        mockOneOnOneResolver = MockOneOnOneResolverInterface()

        sut = ResolveOneOnOneConversationsUseCase(
            context: syncContext,
            supportedProtocolService: mockSupportedProtocolService,
            resolver: mockOneOnOneResolver
        )
    }

    // MARK: - tearDown

    override func tearDown() async throws {
        stack = nil
        mockSupportedProtocolService = nil
        mockOneOnOneResolver = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Unit Tests

    func test_SupportedProtocolsRemainProteusOnly() async throws {
        // GIVEN
        await syncContext.perform { [self] in
            let selfUser = ZMUser.selfUser(in: syncContext)
            selfUser.supportedProtocols = [.proteus]
            mockSupportedProtocolService.calculateSupportedProtocols_MockValue = [.proteus]
        }

        // Mocks
        let pushSupportedProtocolsActionHandler = MockActionHandler<PushSupportedProtocolsAction>(
            result: .success(()),
            context: syncContext.notificationContext
        )

        // WHEN
        try await sut.invoke()

        // THEN
        XCTAssertEqual(pushSupportedProtocolsActionHandler.performedActions.count, 0)
        XCTAssertEqual(mockOneOnOneResolver.resolveAllOneOnOneConversationsIn_Invocations.count, 0)
    }

    func test_SupportedProtocolsChangeFromProteusToProteusAndMLS() async throws {
        // GIVEN
        await syncContext.perform { [self] in
            let selfUser = ZMUser.selfUser(in: syncContext)
            selfUser.supportedProtocols = [.proteus]
            mockSupportedProtocolService.calculateSupportedProtocols_MockValue = [.proteus, .mls]
        }

        // Mocks
        let pushSupportedProtocolsActionHandler = MockActionHandler<PushSupportedProtocolsAction>(
            result: .success(()),
            context: syncContext.notificationContext
        )

        mockOneOnOneResolver.resolveAllOneOnOneConversationsIn_MockMethod = { _ in }

        // WHEN
        try await sut.invoke()

        // THEN
        XCTAssertEqual(pushSupportedProtocolsActionHandler.performedActions.count, 1)
        XCTAssertEqual(mockOneOnOneResolver.resolveAllOneOnOneConversationsIn_Invocations.count, 1)
    }

    func test_SupportedProtocolsRemainProteusAndMLS() async throws {
        // GIVEN
        await syncContext.perform { [self] in
            let selfUser = ZMUser.selfUser(in: syncContext)
            selfUser.supportedProtocols = [.proteus, .mls]
            mockSupportedProtocolService.calculateSupportedProtocols_MockValue = [.proteus, .mls]
        }

        // Mocks
        let pushSupportedProtocolsActionHandler = MockActionHandler<PushSupportedProtocolsAction>(
            result: .success(()),
            context: syncContext.notificationContext
        )

        mockOneOnOneResolver.resolveAllOneOnOneConversationsIn_MockMethod = { _ in }

        // WHEN
        try await sut.invoke()

        // THEN
        XCTAssertEqual(pushSupportedProtocolsActionHandler.performedActions.count, 0)
        XCTAssertEqual(mockOneOnOneResolver.resolveAllOneOnOneConversationsIn_Invocations.count, 1)
    }

    // MARK: Private

    // MARK: - Properties

    private var sut: ResolveOneOnOneConversationsUseCase!
    private var mockSupportedProtocolService: MockSupportedProtocolsServiceInterface!
    private var mockOneOnOneResolver: MockOneOnOneResolverInterface!
    private var stack: CoreDataStack!
    private let coreDataStackHelper = CoreDataStackHelper()

    private var syncContext: NSManagedObjectContext {
        stack.syncContext
    }
}
