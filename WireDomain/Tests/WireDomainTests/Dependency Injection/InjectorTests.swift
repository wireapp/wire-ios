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

import XCTest
import WireDataModel
import WireDataModelSupport
import WireAPISupport
import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class InjectorTests: XCTestCase {
    
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
    }
    
    override func tearDown() async throws {
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }
    
    func testRegisterAlreadyInitialized_Service_It_Resolves_The_Service() throws {
        
        // Given, an already initialized service
        let updateEventsRepository = UpdateEventsRepository(
            userID: .mockID1,
            selfClientID: UUID.mockID2.uuidString,
            updateEventsAPI: MockUpdateEventsAPI(),
            pushChannel: MockPushChannelProtocol(),
            updateEventDecryptor: MockUpdateEventDecryptorProtocol(),
            updateEventsLocalStore: MockUpdateEventsLocalStoreProtocol()
        )
        
        // When, registering the service
        Injector.register(UpdateEventsRepositoryProtocol.self) {
            updateEventsRepository
        }
        
        // Then, the instance is resolved
        let _: UpdateEventsRepositoryProtocol = Injector.resolve()
    }
    
    func testRegisterService_It_Resolves_The_Service_On_The_Fly() throws {
        
        // Given, a registered service not yet initialized
        Injector.register(UpdateEventsRepositoryProtocol.self) { userID, selfClientID, updateEventsAPI, pushChannel, updateEventDecryptor, updateEventsLocalStore in
            UpdateEventsRepository(
                userID: userID,
                selfClientID: selfClientID,
                updateEventsAPI: updateEventsAPI,
                pushChannel: pushChannel,
                updateEventDecryptor: updateEventDecryptor,
                updateEventsLocalStore: updateEventsLocalStore
            )
        }
        
        // When, setting up the service dependencies
        let mockUpdateEventsAPI: UpdateEventsAPI = MockUpdateEventsAPI()
        let mockPushChannel: PushChannelProtocol = MockPushChannelProtocol()
        let mockUpdateEventDecryptor: UpdateEventDecryptorProtocol = MockUpdateEventDecryptorProtocol()
        let mockUpdateEventsLocalStore: UpdateEventsLocalStoreProtocol = MockUpdateEventsLocalStoreProtocol()
        
        // Then, it resolves the service on the fly with the provided dependencies
        let _: UpdateEventsRepositoryProtocol = Injector.resolve(
            arguments: UUID.mockID1, UUID.mockID2.uuidString, mockUpdateEventsAPI, mockPushChannel, mockUpdateEventDecryptor, mockUpdateEventsLocalStore
        )
    }
}
