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

import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import WireNetwork
import XCTest

@testable import WireDomain

final class UserClientRemoveEventProcessorTests: XCTestCase {

    private var sut: UserClientRemoveEventProcessor!
    private var userClientsRepository: MockUserClientsRepositoryProtocol!
    private var calculateSupportedProtocolsUseCase: MockCalculateSupportedProtocolsUseCaseProtocol!
    private var pushSupportedProtocolsUseCase: MockPushSupportedProtocolsUseCaseProtocol!
    private var oneOnOneResolver: MockOneOnOneResolverProtocol!
    private var didInvalidateSelfClient = false

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        userClientsRepository = MockUserClientsRepositoryProtocol()
        calculateSupportedProtocolsUseCase = MockCalculateSupportedProtocolsUseCaseProtocol()
        pushSupportedProtocolsUseCase = MockPushSupportedProtocolsUseCaseProtocol()
        oneOnOneResolver = MockOneOnOneResolverProtocol()

        sut = UserClientRemoveEventProcessor(
            userClientsRepository: userClientsRepository,
            calculateSupportedProtocolsUseCase: calculateSupportedProtocolsUseCase,
            pushSupportedProtocolsUseCase: pushSupportedProtocolsUseCase,
            oneOnOneResolver: oneOnOneResolver,
            context: context,
            onSelfClientInvalidated: { self.didInvalidateSelfClient = true }
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        stack = nil
        modelHelper = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        sut = nil
        userClientsRepository = nil
        calculateSupportedProtocolsUseCase = nil
        pushSupportedProtocolsUseCase = nil
        oneOnOneResolver = nil
        didInvalidateSelfClient = false
    }

    // MARK: - Tests

    func testProcessEvent_When_Client_Is_Self_It_Invokes_User_Repo_Methods() async throws {
        // Mock

        await context.perform { [self] in
            _ = modelHelper.createSelfClient(
                id: Scaffolding.selfClientID,
                in: context
            )
        }

        userClientsRepository.invalidateSelfClient_MockMethod = {}

        // When

        try await sut.processEvent(Scaffolding.removeSelfClientEvent)

        // Then

        XCTAssertEqual(userClientsRepository.invalidateSelfClient_Invocations.count, 1)
        XCTAssertEqual(didInvalidateSelfClient, true)
    }

    func testProcessEvent_When_Client_Is_Not_Self_It_Invokes_User_Repo_Methods() async throws {
        // Mock

        await context.perform { [self] in
            _ = modelHelper.createSelfClient(
                id: Scaffolding.selfClientID,
                in: context
            )
        }

        userClientsRepository.deleteClientId_MockMethod = { _ in }
        userClientsRepository.pullSelfClients_MockMethod = {}
        pushSupportedProtocolsUseCase.invoke_MockMethod = {}
        calculateSupportedProtocolsUseCase.invoke_MockValue = [.mls, .proteus]
        oneOnOneResolver.resolveAllOneOnOneConversations_MockMethod = {}

        // When

        try await sut.processEvent(Scaffolding.removeOtherClientEvent)

        // Then

        XCTAssertEqual(userClientsRepository.deleteClientId_Invocations.count, 1)
        XCTAssertEqual(userClientsRepository.pullSelfClients_Invocations.count, 1)
        XCTAssertEqual(pushSupportedProtocolsUseCase.invoke_Invocations.count, 1)
        XCTAssertEqual(calculateSupportedProtocolsUseCase.invoke_Invocations.count, 1)
        XCTAssertEqual(oneOnOneResolver.resolveAllOneOnOneConversations_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let selfClientID = UUID.mockID1.uuidString
        static let otherClientID = UUID.mockID2.uuidString

        static let removeSelfClientEvent = UserClientRemoveEvent(
            clientID: selfClientID
        )

        static let removeOtherClientEvent = UserClientRemoveEvent(
            clientID: otherClientID
        )
    }

}
