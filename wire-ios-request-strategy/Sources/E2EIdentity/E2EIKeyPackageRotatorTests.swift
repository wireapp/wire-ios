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

import Foundation
import WireCoreCrypto
import XCTest
@testable import WireDataModelSupport
@testable import WireRequestStrategy

class E2EIKeyPackageRotatorTests: MessagingTestBase {
    // MARK: Internal

    override func setUp() {
        super.setUp()

        mockCoreCrypto = MockCoreCryptoProtocol()
        mockCommitSender = MockCommitSending()
        mockConversationEventProcessor = MockConversationEventProcessorProtocol()
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockFeatureRepository = .init()

        sut = E2EIKeyPackageRotator(
            coreCryptoProvider: mockCoreCryptoProvider,
            conversationEventProcessor: mockConversationEventProcessor,
            context: syncMOC,
            onNewCRLsDistributionPointsSubject: .init(),
            commitSender: mockCommitSender,
            featureRepository: mockFeatureRepository
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
        // Core crypto expects the type `E2eiEnrollment`
        // Unfortunately, we cannot mock or stub this type
        // So we're unable to test the behaviour of the key package rotator
        //
        // If core crypto changes method signatures to expect `E2eiEnrollmentProtocol` instead,
        // then we can resolve this.
        // Until then we're unable to test anything that has a dependency on `E2eiEnrollment`
        //
        // TODO: [WPB-6035] Investigate solutions to mock core crypto types
    }

    // MARK: Private

    private var mockCoreCrypto: MockCoreCryptoProtocol!
    private var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var mockCommitSender: MockCommitSending!
    private var mockConversationEventProcessor: MockConversationEventProcessorProtocol!
    private var mockFeatureRepository: MockFeatureRepositoryInterface!
    private var sut: E2EIKeyPackageRotator!
}
