//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAPISupport
import WireDataModel
import WireDataModelSupport
import WireTestingPackage
import XCTest
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class GenerateNotificationServiceTests: XCTestCase {
    private var sut: GenerateNotificationService!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var messageLocalStore: MockMessageLocalStoreProtocol!
    private var didCallNotificationContentHandler = false
    
    override func setUp() async throws {
        conversationLocalStore = MockConversationLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()
        
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = applicationSupport.appendingPathComponent(
            "GenerateNotificationServiceTests"
        )
        
        let asyncStream = AsyncStream<[UpdateEvent]> {
            $0.yield([])
            $0.finish()
        }
        
        sut = GenerateNotificationService(
            eventsStream: asyncStream,
            contentHandler: { [self] _ in didCallNotificationContentHandler = true },
            accountManager: AccountManager(sharedDirectory: url),
            selectedAccount: Account(userName: .init(), userIdentifier: .mockID1),
            userLocalStore: userLocalStore,
            conversationLocalStore: conversationLocalStore,
            messageLocalStore: messageLocalStore
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        conversationLocalStore = nil
        userLocalStore = nil
        messageLocalStore = nil
    }
    
    func testProcess_It_Invokes_Notification_Content_Handler() async throws {
        // When
        await sut.process()
        
        // Then
        XCTAssertEqual(didCallNotificationContentHandler, true)
    }
    
}


