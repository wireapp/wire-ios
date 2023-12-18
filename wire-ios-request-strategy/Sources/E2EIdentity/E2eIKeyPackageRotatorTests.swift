//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireCoreCrypto

@testable import WireRequestStrategy
@testable import WireDataModelSupport

class E2eIKeyPackageRotatorTests: MessagingTestBase {

    private var mockCoreCrypto: MockCoreCrypto!
    private var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var mockCommitSender: MockCommitSending!
    private var mockConversationEventProcessor: MockConversationEventProcessorProtocol!
    private var sut: E2eIKeyPackageRotator!

    override func setUp() {
        super.setUp()

        mockCoreCrypto = MockCoreCrypto()
        mockCommitSender = MockCommitSending()
        mockConversationEventProcessor = MockConversationEventProcessorProtocol()
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCryptoRequireMLS_MockValue = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)

        sut = E2eIKeyPackageRotator(
            coreCryptoProvider: mockCoreCryptoProvider,
            conversationEventProcessor: mockConversationEventProcessor,
            context: syncMOC,
            commitSender: mockCommitSender
        )
    }

    override func tearDown() {
        mockCoreCrypto = nil
        mockCoreCryptoProvider = nil
        mockConversationEventProcessor = nil
        sut = nil

        super.tearDown()
    }

    func test_rotateKeys() {
        // In the implementation of `rotateKeysAndMigrateConversations`
        // Core crypto expects the type `WireE2eIdentity`
        // Unfortunately, we cannot mock or stub this type
        // So we're unable to test the behaviour of the key package rotator
        //
        // If core crypto changes method signatures to expect a type we're able to mock,
        // Or we implement a wrapper around `WireE2eIdentity` to enable mocking,
        // Then we can resolve this.
        // Until then we're unable to test anything that has a dependency on `WireE2eIdentity`
        //
        // TODO: Create a ticket to track this
    }

}
